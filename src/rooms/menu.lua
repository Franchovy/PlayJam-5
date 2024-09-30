import "menu/grid"

local pd <const> = playdate
local sound <const> = pd.sound
local gfx <const> = pd.graphics
local systemMenu <const> = pd.getSystemMenu()

local spButton <const> = sound.sampleplayer.new(assets.sounds.menuSelect)

class ("Menu").extends(Room)

local sceneManager

---
--- LIFECYCLE
---
--
function Menu:enter(fileplayer)
  self.fileplayer = fileplayer

  sceneManager = self.manager

  self.gridView = MenuGridView.new()

  systemMenu:addMenuItem("reset progress", MemoryCard.resetProgress)

  -- TODO: if last played is 100% complete, select _next_ level
  -- and if all levels are 100% complete, just set to 1-1
  -- STRETCH: cool new state or animationg for 100% completion
  local level = MemoryCard.getLastPlayed()

  -- Position current row in center of screen
  -- Wrapped in a timer delay to allow the gridview to initialize.

  playdate.timer.performAfterDelay(1, function()
    self.gridView:setSelection(level or 1)
  end)
end

function Menu:leave()
    systemMenu:removeAllMenuItems()
end

function Menu:setMenuLabelText(text)
  assert(text and type(text) == "string")

  local textImage = gfx.imageWithText(text, 300, 80, nil, nil, nil, kTextAlignment.center)

  spritePressStart:setImage(textImage:invertedImage())
end

function Menu:update()
  self.gridView:drawInRect(0, 0, 400, 240)
end

---
--- INPUT
---

function Menu:AButtonDown()
  fileplayer:stop()

  local level = self.gridView:getSelectedLevel()
  if level then
    LDtk.load(assets.path.levels..level..".ldtk")
    spButton:play(1)
    MemoryCard.setLastPlayed(level)

    sceneManager.scenes.currentGame = Game()
    sceneManager:enter(sceneManager.scenes.currentGame, {isInitialLoad = true})
  end
end

function Menu:BButtonDown()
  sceneManager:enter(sceneManager.scenes.start)
end

function Menu:downButtonDown()
  self.gridView:selectNextRow(false, true, true)
end

function Menu:upButtonDown()
  self.gridView:selectPreviousRow(false, true, true)
end
