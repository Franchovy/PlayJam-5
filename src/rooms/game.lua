class("Game").extends(Room)

local sceneManager
local systemMenu <const> = playdate.getSystemMenu()

local function goToMainMenu()
    sceneManager:enter(sceneManager.scenes.menu)
end

local function restartLevel()
    sceneManager:enter(sceneManager.scenes.currentGame)
end

local levelName <const> = "Level_0"

function Game:enter(previous, ...)
    -- Set local reference to sceneManager

    sceneManager = self.manager

    -- Load level

    LDtk.loadAllLayersAsSprites(levelName)
    LDtk.loadAllEntitiesAsSprites(levelName)

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
