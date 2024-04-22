local pd <const> = playdate
local sound <const> = pd.sound

class("Game").extends(Room)

local sceneManager
local systemMenu <const> = pd.getSystemMenu()
local forceShowPanel = false



local spCollect = sound.sampleplayer.new("assets/sfx/Collect")
local spWin = sound.sampleplayer.new("assets/sfx/Win")
local spItemDrop = sound.sampleplayer.new("assets/sfx/Discard")

local function goToMainMenu()
    sceneManager:enter(sceneManager.scenes.menu)
end

local function restartLevel()
    sceneManager:enter(sceneManager.scenes.currentGame)
end

function Game:init(lvl)
    self.level = lvl
end

function Game:enter(previous, ...)
    -- Set local reference to sceneManager

    sceneManager = self.manager
    sceneManager.scenes.currentGame = self

    -- Load Ability Panel

    self.abilityPanel = AbilityPanel()

    -- Load level

    local levelName = "Level_" .. self.level
    local hintCrank = LDtk.loadAllLayersAsSprites(levelName)
    pd.timer.new(1500, function()
        self.hintCrank = hintCrank
        pd.timer.new(3000, function()
            self.hintCrank = false
        end)
    end)

    LDtk.loadAllEntitiesAsSprites(levelName)

    -- Menu items
    systemMenu:addMenuItem("main menu", goToMainMenu)
    systemMenu:addMenuItem("restart", restartLevel)

    -- Show ability Panel (3s)

    self.abilityPanel:animate(true)
    forceShowPanel = true
    pd.timer.performAfterDelay(3000, function()
        forceShowPanel = false
        self.abilityPanel:animate(false)
    end)
end

function Game:update(dt)
    -- update entities
    if self.hintCrank then
        pd.ui.crankIndicator:draw()
    end

    if self.fileplayer == nil then
        self:setupFilePlayer()

        self.fileplayer:play()
    end
end

function Game:leave(next, ...)
    -- Menu items

    pd.graphics.sprite.removeAll()
    systemMenu:removeAllMenuItems()

    -- Remove currentGame reference from manager
    sceneManager.scenes.currentGame = nil

    -- Music

    if next.super.className == "Menu" then
        self.fileplayer:stop()
        self.fileplayer = nil
    end
end

function Game:draw()
    -- draw the level
end

-- Fileplayer

function Game:setupFilePlayer()
    self.fileplayer = SuperFilePlayer()

    if self.level >= 6 then
        self.fileplayer:loadFiles("assets/music/robot-cavern/1", "assets/music/robot-cavern/2",
            "assets/music/robot-cavern/3", "assets/music/robot-cavern/4")

        self.fileplayer:setPlayConfig(4, 4, 3, 2)
    else
        self.fileplayer:loadFiles("assets/music/robot-redux/1", "assets/music/robot-redux/2",
            "assets/music/robot-redux/3", "assets/music/robot-redux/4")

        self.fileplayer:setPlayConfig(2, 2, 3, 2)
    end
end

-- Events

local maxLevels <const> = 10

function Game:levelComplete()
    spWin:play(1)

    local levelPrevious = self.level
    self.level = self.level + 1

    if self.level >= maxLevels then
        self.level = 0
        goToMainMenu()
        pd.datastore.write({ LEVEL = 0 })
    else
        self:cleanUp()
        sceneManager.scenes.currentGame = Game(self.level)
        sceneManager:enter(sceneManager.scenes.currentGame)

        local saveData = pd.datastore.read()
        if not saveData or saveData.LEVEL < self.level then
            pd.datastore.write({ LEVEL = self.level })
        end
    end

    if self.level == 6 and levelPrevious == 5 then
        -- Switch Music
        self.fileplayer:stop()

        self.fileplayer = nil
    end
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
