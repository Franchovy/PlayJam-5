local pd <const> = playdate
local gfx <const> = pd.graphics
local sound <const> = pd.sound

class("Game").extends(Room)

local sceneManager
local systemMenu <const> = pd.getSystemMenu()

local fileplayer

local spCollect = sound.sampleplayer.new("assets/sfx/Collect")
local spWin = sound.sampleplayer.new("assets/sfx/Win")
local spItemDrop = sound.sampleplayer.new("assets/sfx/Discard")

-- LDtk current level name
local initialLevelName <const> = "Level_0"
local currentLevelName
local checkpointPlayerStart

local function goToMainMenu()
    sceneManager:enter(sceneManager.scenes.menu)
end

local function restartLevel()
    local level, checkpoint

    local spriteCheckpoint = Checkpoint.getLatestCheckpoint()
    if spriteCheckpoint then
        level = { name = spriteCheckpoint.levelName }
        checkpoint = spriteCheckpoint
    else
        level = initialLevelName
        checkpoint = checkpointPlayerStart
    end

    sceneManager:enter(sceneManager.scenes.currentGame, { level = level, checkpoint = checkpoint })
end

function Game:init() end

function Game:enter(previous, data)
    data = data or {}
    local direction = data.direction
    local level = data.level
    local checkpoint = data.checkpoint

    -- This should run only once to initialize the game instance.

    if not self.isInitialized then
        self.isInitialized = true

        -- Set local reference to sceneManager

        sceneManager = self.manager
        sceneManager.scenes.currentGame = self

        -- Load Ability Panel

        self.abilityPanel = AbilityPanel()

        -- Menu items

        systemMenu:addMenuItem("main menu", goToMainMenu)
        systemMenu:addMenuItem("restart", restartLevel)
    end

    -- Load level --

    currentLevelName = level and level.name or initialLevelName
    local levelBounds = level and level.bounds or LDtk.get_rect(currentLevelName)

    local hintCrank = LDtk.loadAllLayersAsSprites(currentLevelName)

    pd.timer.new(1500, function()
        self.hintCrank = hintCrank
        pd.timer.new(3000, function()
            self.hintCrank = false
        end)
    end)

    LDtk.loadAllEntitiesAsSprites(currentLevelName)

    local player = Player.getInstance()

    if not checkpointPlayerStart then
        checkpointPlayerStart = {
            x = player.x,
            y = player.y,
            blueprints = table.deepcopy(player.keys)
        }
    end

    if player then
        player:add()

        if checkpoint then
            player:setBlueprints(checkpoint.blueprints)
            player:moveTo(checkpoint.x, checkpoint.y)
        end

        player:enterLevel(direction, levelBounds)
    end

    local abilityPanel = AbilityPanel.getInstance()

    if abilityPanel then
        abilityPanel:add()

        if checkpoint then
            abilityPanel:setItems(table.unpack(checkpoint.blueprints))
        end
    end
end

function Game:update()
    -- update entities
    if self.hintCrank then
        pd.ui.crankIndicator:draw()
    end

    if fileplayer == nil then
        self:setupFilePlayer()

        fileplayer:play()
    end
end

function Game:leave(next, ...)
    -- Clear sprites in level

    gfx.sprite.removeAll()

    --

    if next.super.className == "Menu" then
        -- Remove system/PD menu items

        systemMenu:removeAllMenuItems()

        -- Remove currentGame reference from manager
        sceneManager.scenes.currentGame = nil

        -- Stop the music!

        fileplayer:stop()
        fileplayer = nil
    end
end

-- Fileplayer

function Game:setupFilePlayer()
    fileplayer = SuperFilePlayer()

    fileplayer:loadFiles("assets/music/01_Mine")

    fileplayer:setPlayConfig(1)
end

-- Events

local maxLevels <const> = 10

function Game:levelComplete(data)
    local direction = data.direction
    local coordinates = data.coordinates

    spWin:play(1)

    -- Load next level

    function getNeighborLevelForPos(neighbors, position)
        assert(#neighbors > 0)

        for _, levelName in pairs(neighbors) do
            local levelBounds = LDtk.get_rect(levelName)
            if levelBounds.x < position.x and levelBounds.x + levelBounds.width > position.x and
                levelBounds.y < position.y and levelBounds.y + levelBounds.height > position.y then
                return levelName, levelBounds
            end
        end
    end

    local neighbors = LDtk.get_neighbours(currentLevelName, direction)

    -- Check coordinates function for detecting which neighbor to transition to
    local nextLevel, nextLevelBounds = getNeighborLevelForPos(neighbors, coordinates)

    sceneManager:enter(sceneManager.scenes.currentGame,
        { direction = direction, level = { name = nextLevel, bounds = nextLevelBounds } })
end

function Game:loadItems(item1, item2, item3)
    self.abilityPanel:setItems(item1, item2, item3)
end

function Game:cleanUp()
    self.abilityPanel:cleanUp()
end

function Game:pickup(blueprint)
    blueprint:updateStatePickedUp()

    spCollect:play(1)
    self.abilityPanel:addItem(blueprint.ability)
end

function Game:crankDrop()
    spItemDrop:play()
    self.abilityPanel:removeRightMost()
end

function Game:checkpointIncrement()
    Checkpoint.increment()
end

function Game:checkpointRevert()
    Checkpoint.goToPrevious()
end
