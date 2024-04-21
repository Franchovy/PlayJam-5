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
  self.startingItem = self:startingItemForLevel(lvl)
end


function Game:enter(previous, ...)
    -- Set local reference to sceneManager

    sceneManager = self.manager
    -- Load level
    local levelName = "Level_"..self.level
    LDtk.loadAllLayersAsSprites(levelName)
    LDtk.loadAllEntitiesAsSprites(self, levelName, self.startingItem)

    self.abilityPanel = AbilityPanel(self.startingItem)

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
      sceneManager.scenes.currentGame = Game(self.level, self.startingItem)
      sceneManager:enter(sceneManager.scenes.currentGame)
    end
end

-- wow, this is inelegant!
function Game:startingItemForLevel(level)
  if level == 0 then
    return "right"
  elseif level == 1 then
    return "right"
  elseif level == 2 then
    return "left"
  end
  return "right"
end

function Game:itemPickedUp(item)
  self.abilityPanel:addItem(item)
end

function Game:cleanUp()
  self.abilityPanel:destroy()
end
