local pd <const> = playdate
local sound <const> = pd.sound
local gfx <const> = pd.graphics
local systemMenu <const> = pd.getSystemMenu()
import "menuGrid"

class ("Menu").extends(Room)

local sceneManager
local spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")

---
--- LIFECYCLE
---
--
function Menu:enter()
  sceneManager = self.manager


  self.gridView = MenuGrid.new(self.a)

  systemMenu:addMenuItem("reset progress", MemoryCard.resetProgress)

  -- TODO: if last played is 100% complete, select _next_ level
  -- and if all levels are 100% complete, just set to 1-1
  -- STRETCH: cool new state or animationg for 100% completion
  local world, level = MemoryCard.getLastPlayed()
  if not world then
    world = 1
  end
  if not level then
    level = 1
  end
  MenuGrid.resetAnimator(world, level)
  self.gridView:scrollToCell(world, level, 1)
  self.gridView:setSelection(world, level, 1)
end

function Menu:leave()
    systemMenu:removeAllMenuItems()
end

function Menu:update()
  self.gridView:drawInRect(0, 0, 400, 240)
end

---
--- INPUT
---

function Menu:AButtonDown()
  local section, row = self.gridView:getSelection()
  local levelFile = ReadFile.getLevel(section, row)
  if levelFile then
    LDtk.load(assets.path.levels..levelFile)
    spButton:play(1)
    MemoryCard.setLastPlayed(section, row)
    sceneManager.scenes.currentGame = Game(0)
    sceneManager:enter(sceneManager.scenes.currentGame)
  end
end

function Menu:BButtonDown()
  sceneManager:enter(sceneManager.scenes.start)
end

function Menu:downButtonDown()
  local section, row = self.gridView:getSelection()
  -- returning early so the grid doesn't scroll wrap
  -- `selectPreviousRow` has a flag for that but we also
  -- want to check we are going to change selected cell
  -- before `resetAnimator` so odd redundancy here
  if(not section or section > 4) then return end
  MenuGrid.resetAnimator(section, row)
  self.gridView:selectNextRow(false, true, true)
end

function Menu:upButtonDown()
  local section, row = self.gridView:getSelection()
  -- returning early so the grid doesn't scroll wrap
  -- `selectPreviousRow` has a flag for that but we also
  -- want to check we are going to change selected cell
  -- before `resetAnimator` so odd redundancy here
  if (not section or section < 1) then return end
  MenuGrid.resetAnimator(section, row)
  self.gridView:selectPreviousRow(false, true, true)
end
