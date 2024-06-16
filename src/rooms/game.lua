local pd <const> = playdate
local gfx <const> = pd.graphics
local sound <const> = pd.sound

class("Game").extends(Room)

local sceneManager
local systemMenu <const> = pd.getSystemMenu()
local forceShowPanel = false

local fileplayer

local spCollect = sound.sampleplayer.new("assets/sfx/Collect")
local spWin = sound.sampleplayer.new("assets/sfx/Win")
local spItemDrop = sound.sampleplayer.new("assets/sfx/Discard")

-- LDtk current level name
local initialLevelName <const> = "Level_0"
local currentLevelName

local function goToMainMenu()
    sceneManager:enter(sceneManager.scenes.menu)
end

local function restartLevel()
    sceneManager:enter(sceneManager.scenes.currentGame)
end

function Game:init() end

function Game:enter(previous, data)
    data = data or {}
    local direction = data.direction
    local nextLevelName = data.nextLevelName

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

    -- Load level

    currentLevelName = nextLevelName or initialLevelName

    local hintCrank = LDtk.loadAllLayersAsSprites(currentLevelName)
    pd.timer.new(1500, function()
        self.hintCrank = hintCrank
        pd.timer.new(3000, function()
            self.hintCrank = false
        end)
    end)

    LDtk.loadAllEntitiesAsSprites(currentLevelName)

    local player = Player.getInstance()
    if player ~= nil then
        player:add()

        local levelBounds = LDtk.get_rect(currentLevelName)
        player:enterLevel(direction, levelBounds)
    end

    -- Show ability Panel (3s)

    self.abilityPanel:animate(true)
    forceShowPanel = true
end

function Game:update(dt)
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

    if next.super.className == "Menu" or next.super.className == "GameComplete" then
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

    fileplayer:loadFiles("assets/music/robot-cavern/1", "assets/music/robot-cavern/2",
        "assets/music/robot-cavern/3", "assets/music/robot-cavern/4")

    fileplayer:setPlayConfig(4, 4, 3, 2)
end

-- Events

local maxLevels <const> = 10

function Game:levelComplete(data)
    local direction = data.direction

    spWin:play(1)

    -- Load next level

    local neighbors = LDtk.get_neighbours(currentLevelName, direction)

    -- For now, just get the first neightbor. For handling multiple neighbors we'll have to do a coordinates check.
    local nextLevel = neighbors[1]

    sceneManager:enter(sceneManager.scenes.currentGame, { direction = direction, nextLevelName = nextLevel })
end

function Game:loadItems(item1, item2, item3)
    self.abilityPanel:setItems(item1, item2, item3)
end

function Game:cleanUp()
    self.abilityPanel:cleanUp()
end

function Game:pickup(object)
    spCollect:play(1)
    self.abilityPanel:addItem(object.abilityName)
    object:remove()
end

function Game:crankDrop()
    spItemDrop:play()
    self.abilityPanel:removeRightMost()
end

function Game:showPanel(isShowing)
    if forceShowPanel then
        return
    end

    self.abilityPanel:animate(isShowing)
end
