local pd <const> = playdate
local sound <const> = pd.sound
local gfx <const> = pd.graphics
local ui <const> = pd.ui
local systemMenu <const> = pd.getSystemMenu()

class ("Menu").extends(Room)

local sceneManager
local spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")

local CELL_HEIGHT <const> = 110
local CELL_INSETS <const> = 5
local CELL_PADDING_V <const> = 8
local CELL_PADDING_H = 5
local CELL_WIDTH <const> = 400 - (CELL_INSETS * 2) - (CELL_PADDING_H * 2)

local CELL_FILL_ANIM_SPEED <const> = 800

local gridView = ui.gridview.new(0, CELL_HEIGHT)
gridView:setNumberOfSections(4)
gridView:setNumberOfRows(4, 4, 4, 4)
gridView:setCellPadding(CELL_PADDING_H, CELL_PADDING_H, CELL_PADDING_V, CELL_PADDING_V)
gridView:setContentInset(CELL_INSETS, CELL_INSETS, CELL_INSETS, CELL_INSETS)
gridView:setSectionHeaderHeight(48)
gridView:setNumberOfColumns(1)

local a = gfx.animator.new(CELL_FILL_ANIM_SPEED, 0, CELL_WIDTH, playdate.easingFunctions.inOutQuad)

---
--- LOCAL HELPERS
---

local function resetAnimator(section, row)
  -- TODO: total/rescued not tracked currently, put this back for width
  local total, rescued = MemoryCard.getLevelCompletion(section, row);
  local width = (rescued / total) * CELL_WIDTH
  a = gfx.animator.new(CELL_FILL_ANIM_SPEED, 0, CELL_WIDTH, playdate.easingFunctions.inOutQuad)
end

---
--- LIFECYCLE
---
--
function Menu:enter()
  sceneManager = self.manager

  systemMenu:addMenuItem("reset progress", MemoryCard.resetProgress)

  -- TODO: if last played is 100% complete, select _next_ level
  -- and if all levels are 100% complete, just set to 1-1
  -- STRETCH: cool new state or animationg for 100% completion
  local world, level = MemoryCard.getLastPlayed()
  resetAnimator(world, level)
  gridView:scrollToCell(world, level, 1)
  gridView:setSelection(world, level, 1)
end

function Menu:leave()
    systemMenu:removeAllMenuItems()
end

function Menu:update()
  gridView:drawInRect(0, 0, 400, 240)
end

---
--- INPUT
---

function Menu:AButtonDown()
  local section, row = gridView:getSelection()
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
  local section, row = gridView:getSelection()
  -- returning early so the grid doesn't scroll wrap
  -- `selectPreviousRow` has a flag for that but we also
  -- want to check we are going to change selected cell
  -- before `resetAnimator` so odd redundancy here
  if(not section or section > 4) then return end
  resetAnimator(section, row)
  gridView:selectNextRow(false, true, true)
end

function Menu:upButtonDown()
  local section, row = gridView:getSelection()
  -- returning early so the grid doesn't scroll wrap
  -- `selectPreviousRow` has a flag for that but we also
  -- want to check we are going to change selected cell
  -- before `resetAnimator` so odd redundancy here
  if (not section or section < 1) then return end
  resetAnimator(section, row)
  gridView:selectPreviousRow(false, true, true)
end

--
-- GRIDVIEW
--

function gridView:drawSectionHeader(section, x, y, width, height)
	local fontHeight = gfx.getSystemFont():getHeight()
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawTextAligned("*WORLD " .. section .. "*", x + width / 2, y + (height/2 - fontHeight/2) + 2, kTextAlignment.center)
end

function gridView:drawCell(section, row, column, selected, x, y, width, height)
  gfx.setDitherPattern(0.1, gfx.image.kDitherTypeDiagonalLine)
  if selected then
    gfx.fillRoundRect(x, y, a:currentValue(), CELL_HEIGHT, 10)
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.setLineWidth(3)
  else
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.setLineWidth(1)
  end
	local fontHeight = 50
	gfx.drawTextAligned(section..' - '..row, x + width / 2, y + (height/2 - fontHeight/2) + 2, kTextAlignment.center)
  gfx.setColor(gfx.kColorWhite)
  gfx.drawRoundRect(x, y, width, height, 10)
end


