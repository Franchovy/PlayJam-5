class("Game").extends(Room)

local sceneManager
local systemMenu <const> = playdate.getSystemMenu()
local forceShowPanel = false

SuperFilePlayer.loadFiles("assets/music/1", "assets/music/2", "assets/music/3", "assets/music/4")
SuperFilePlayer.setPlayConfig(4, 4, 2, 2)

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
    playdate.timer.new(1500, function()
        self.hintCrank = hintCrank
        playdate.timer.new(3000, function()
            self.hintCrank = false
        end)
    end)

    LDtk.loadAllEntitiesAsSprites(levelName)

    -- Menu items
    systemMenu:addMenuItem("main menu", goToMainMenu)
    systemMenu:addMenuItem("restart", restartLevel)

    -- Music
    if previous.super.className == "Menu" then
        SuperFilePlayer.play()
    end

    -- Show ability Panel (3s)

    self.abilityPanel:animate(true)
    forceShowPanel = true
    playdate.timer.performAfterDelay(3000, function()
        forceShowPanel = false
        self.abilityPanel:animate(false)
    end)
end

function Game:update(dt)
    -- update entities
    if self.hintCrank then
        playdate.ui.crankIndicator:draw()
    end
end

function Game:leave(next, ...)
    -- Menu items

    playdate.graphics.sprite.removeAll()
    systemMenu:removeAllMenuItems()

    -- Remove currentGame reference from manager
    sceneManager.scenes.currentGame = nil

    -- Music
    if next.super.className == "Menu" then
        SuperFilePlayer.stop()
    end
end

function Game:draw()
    -- draw the level
end

local maxLevels <const> = 10

function Game:levelComplete()
    self.level = self.level + 1
    if self.level >= maxLevels then
        self.level = 0
        goToMainMenu()
        playdate.datastore.write({ LEVEL = 0 })
    else
        self:cleanUp()
        sceneManager.scenes.currentGame = Game(self.level)
        sceneManager:enter(sceneManager.scenes.currentGame)

        local saveData = playdate.datastore.read()
        if not saveData or saveData.LEVEL < self.level then
            playdate.datastore.write({ LEVEL = self.level })
        end
    end
end

function Game:loadItems(item1, item2, item3)
    self.abilityPanel:setItems(item1, item2, item3)
end

function Game:cleanUp()
    self.abilityPanel:cleanUp()
end

function Game:pickup(object)
    self.abilityPanel:addItem(object.abilityName)
    object:remove()
end

function Game:crankDrop()
    self.abilityPanel:removeRightMost()
end

function Game:showPanel(isShowing)
    if forceShowPanel then
        return
    end

    self.abilityPanel:animate(isShowing)
end
