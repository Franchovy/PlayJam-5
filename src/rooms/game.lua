class("Game").extends(Room)

local sceneManager
local systemMenu <const> = playdate.getSystemMenu()

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
    -- Load level
    local levelName = "Level_" .. self.level
    LDtk.loadAllLayersAsSprites(levelName)
    LDtk.loadAllEntitiesAsSprites(levelName)

    self.abilityPanel = AbilityPanel()

    -- Menu items
    systemMenu:addMenuItem("main menu", goToMainMenu)
    systemMenu:addMenuItem("restart", restartLevel)
end

function Game:update(dt)
    -- update entities
end

function Game:leave(next, ...)
    -- Menu items

    playdate.graphics.sprite.removeAll()
    systemMenu:removeAllMenuItems()

    -- Remove currentGame reference from manager
    sceneManager.scenes.currentGame = nil
end

function Game:draw()
    -- draw the level
end

local maxLevels <const> = 3

function Game:levelComplete()
    self.level = self.level + 1
    if self.level >= maxLevels then
        self.level = 0
        goToMainMenu()
    else
        self:cleanUp()
        sceneManager.scenes.currentGame = Game(self.level)
        sceneManager:enter(sceneManager.scenes.currentGame)
    end
end

function Game:cleanUp()
    self.abilityPanel:cleanUp()
end

function Game:pickup(object)
    self.abilityPanel:addItem(object.abilityName)
    object:remove()
end
