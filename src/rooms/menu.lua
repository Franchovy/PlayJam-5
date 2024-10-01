import "menu/grid"

local gfx <const> = playdate.graphics
local systemMenu <const> = playdate.getSystemMenu()

local spButton <const> = playdate.sound.sampleplayer.new(assets.sounds.menuSelect)

class ("Menu").extends(Room)

local sceneManager

---
--- LIFECYCLE
---
--
function Menu:enter(previous, data)
  local data = data or {}

  if not FilePlayer.isPlaying() then
    FilePlayer.play(assets.music.menu)
  end

  sceneManager = self.manager

  gfx.setDrawOffset(0, 0)

  if not self.gridView then
    self.gridView = MenuGridView.new()
  end

  systemMenu:addMenuItem("reset progress", MemoryCard.resetProgress)

  self.gridView:setSelectionNextLevel()
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
  self.gridView:update()
end

---
--- INPUT
---

function Menu:AButtonDown()
  FilePlayer.stop()

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
