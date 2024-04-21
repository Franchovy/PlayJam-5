class("Game").extends(Room)

local sceneManager
local systemMenu <const> = playdate.getSystemMenu()

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

    self.abilityPanel = AbilityPanel()

    -- Menu items
    systemMenu:addMenuItem("main menu", goToMainMenu)
    systemMenu:addMenuItem("restart", restartLevel)

    -- Music
    if previous.super.className == "Menu" then
        SuperFilePlayer.play()
    end
end

function Game:update(dt)
    -- update entities
    self.abilityPanel:gameUpdate()
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

local maxLevels <const> = 3

function Game:levelComplete()
    local saveData = playdate.datastore.read()
    self.level = self.level + 1
    if self.level >= maxLevels then
        self.level = 0
        goToMainMenu()
        playdate.datastore.write({LEVEL=0})
    else
        self:cleanUp()
        sceneManager.scenes.currentGame = Game(self.level)
        sceneManager:enter(sceneManager.scenes.currentGame)
      if saveData < self.level then
          playdate.datastore.write({LEVEL=self.level})
      end
    end
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
