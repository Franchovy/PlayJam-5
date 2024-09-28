import "menu/grid"

local pd <const> = playdate
local sound <const> = pd.sound
local gfx <const> = pd.graphics
local systemMenu <const> = pd.getSystemMenu()

local spButton <const> = sound.sampleplayer.new("assets/sfx/ButtonSelect")

class ("Menu").extends(Room)

local sceneManager

---
--- LIFECYCLE
---
--
function Menu:enter()
  sceneManager = self.manager

  self.gridView = MenuGridView.new()

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

  -- Position current row in center of screen

  self.gridView:setSelection(world, level, 1, false)
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
  local section, row = self.gridView:getSelection()
  local levelFile = ReadFile.getLevel(section, row)
  if levelFile then
    LDtk.load(assets.path.levels..levelFile)
    spButton:play(1)
    MemoryCard.setLastPlayed(section, row)
    local levelData = LEVEL_DATA.worlds[section].levels[row]

    sceneManager.scenes.currentGame = Game(0)
    sceneManager:enter(sceneManager.scenes.currentGame, levelData)
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
