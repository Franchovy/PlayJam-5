local pd <const> = playdate
local gfx <const> = pd.graphics
local sound <const> = pd.sound

class("Game").extends(Room)

local sceneManager
local systemMenu <const> = pd.getSystemMenu()

local fileplayer

-- LDtk current level name

local initialLevelName <const> = "Level_0"
local currentLevelName
local checkpointPlayerStart

-- Sprites

local botsToRescueCount <const> = 3
local spriteGuiRescueCounter

-- Static methods

function Game.getLevelName()
    return currentLevelName
end

-- Private Methods

local function goToStart()
    sceneManager:enter(sceneManager.scenes.start)
end

-- Instance methods

function Game:init()
    self.checkpointHandler = CheckpointHandler.getOrCreate("game", self)
end

function Game:enter(previous, data)
    data = data or {}
    local direction = data.direction
    local level = data.level
    local isCheckpointRevert = data.isCheckpointRevert

    -- Load rescuable bot array

    if data.isInitialLoad then
        local botRescueCount = botsToRescueCount

        -- Set up GUI

        if not spriteGuiRescueCounter then
            spriteGuiRescueCounter = SpriteRescueCounter()
        end

        spriteGuiRescueCounter:setRescueSpriteCount(botRescueCount)
    end

    -- This should run only once to initialize the game instance.

    if not self.isInitialized then
        self.isInitialized = true

        -- Set local reference to sceneManager

        sceneManager = self.manager
        sceneManager.scenes.currentGame = self

        -- Load Ability Panel

        self.abilityPanel = AbilityPanel()

        -- Menu items

        systemMenu:addMenuItem("back to start", goToStart)
    end

    -- Load level --

    currentLevelName = level and level.name or initialLevelName
    local levelBounds = level and level.bounds or LDtk.get_rect(currentLevelName)

    if not isCheckpointRevert then
        self.checkpointHandler:pushState({ levelName = currentLevelName })
    end

    local hintCrank = LDtk.loadAllLayersAsSprites(currentLevelName)

    pd.timer.new(1500, function()
        self.hintCrank = hintCrank
        pd.timer.new(3000, function()
            self.hintCrank = false
        end)
    end)

    LDtk.loadAllEntitiesAsSprites(currentLevelName)

    local player = Player.getInstance()

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
    end

    local rescueCounter = SpriteRescueCounter.getInstance()

    if rescueCounter then
        rescueCounter:add()
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

    if next.super.className == "Start" or next.super.className == "Menu" then
        -- Remove system/PD menu items

        systemMenu:removeAllMenuItems()

        -- Remove currentGame reference from manager
        sceneManager.scenes.currentGame = nil

        -- Stop the music!

        fileplayer:stop()
        fileplayer = nil
    end
end

-- Checkpoint interface

function Game:handleCheckpointRevert(state)
    if currentLevelName ~= state.levelName then
        sceneManager:enter(sceneManager.scenes.currentGame,
            { level = { name = state.levelName }, isCheckpointRevert = true })
    end
end

-- Fileplayer

function Game:setupFilePlayer()
    fileplayer = SuperFilePlayer()

    fileplayer:loadFiles(assets.music.world1)

    fileplayer:setPlayConfig(1)
end

-- Event-based methods


local maxLevels <const> = 10

function Game:levelComplete(data)
    local direction = data.direction
    local coordinates = data.coordinates

    -- Load next level

    local nextLevel, nextLevelBounds = LDtk.getNeighborLevelForPos(currentLevelName, direction, coordinates)

    sceneManager:enter(sceneManager.scenes.currentGame,
        { direction = direction, level = { name = nextLevel, bounds = nextLevelBounds } })
end

function Game:botRescued(bot, botNumber)
    spriteGuiRescueCounter:setSpriteRescued(botNumber)
end

function Game:updateBlueprints()
    local abilityPanel = AbilityPanel.getInstance()
    abilityPanel:updateBlueprints()
end

function Game:checkpointIncrement()
    Checkpoint.increment()
end

function Game:checkpointRevert()
    Checkpoint.goToPrevious()
end

function Game:hideOrShowGui(shouldHide)
    local abilityPanel = AbilityPanel.getInstance()

    if shouldHide then
        abilityPanel:hide()
    else
        abilityPanel:show()
    end
end
