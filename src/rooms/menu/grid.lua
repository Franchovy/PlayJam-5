local pd <const> = playdate
local gfx <const> = pd.graphics
local ui <const> = pd.ui

local LEVEL_DATA <const> = LEVEL_DATA

local CELL_HEIGHT <const> = 110
local CELL_INSETS <const> = 5
local CELL_PADDING_V <const> = 8
local CELL_PADDING_H <const> = 5
local CELL_FILL_ANIM_SPEED <const> = 800
local CELL_WIDTH <const> = 400 - (CELL_INSETS * 2) - (CELL_PADDING_H * 2)

local animatorGridCell

class("MenuGridView").extends()

---
--- Local convenience functions
---

local function resetAnimator(self)
  local section, row = self.gridView:getSelection()
  local total, rescued = MemoryCard.getLevelCompletion(section, row);

  -- TODO: total/rescued not tracked currently, remove this for dynamic width
  rescued = total

  local width = (rescued / total) * CELL_WIDTH
  self.animatorGridCell = gfx.animator.new(CELL_FILL_ANIM_SPEED, 0, width, pd.easingFunctions.inOutQuad)
end

local function isFirstOrLastCell(self, section, row)
  if section == 1 and row == 1 then
    -- is First cell
    return false
  elseif section == #LEVEL_DATA.worlds and row == #LEVEL_DATA.worlds[#LEVEL_DATA.worlds].levels then
    -- is last cell
    return false
  end

  return true
end

local function animateSelectionChange(self, callback, ...)
  local sectionPrevious, rowPrevious = self.gridView:getSelection()

  callback(self.gridView, ...)

  local section, row = self.gridView:getSelection()

  if sectionPrevious ~= section or rowPrevious ~= row then
    -- [Franch] NOTE: There seems to be a bug where scrolling to the last cell for some reason
    -- blocks scrolling indefinitely. Not sure what's causing it.
    -- Work-around is to disable scrolling and only scroll this is the first or last row.

    if isFirstOrLastCell(self, section, row) then
      self.gridView:scrollCellToCenter(section, row, 1)
    else
      self.gridView:scrollToCell(section, row, 1)
    end

    resetAnimator(self)
  end
end

---
--- MenuGridView object
---

function MenuGridView.new()
  return MenuGridView()
end

function MenuGridView:init()
  self.gridView = ui.gridview.new(0, CELL_HEIGHT)

  -- No super init call available on gridView, so let's redirect missed function calls on super to the gridview object.
  local mt = {
    __index = function(table, key)
      return self.gridView[key]
    end
  }
  setmetatable(MenuGridView.super, mt)

  -- Set number of sections & rows
  self.gridView:setNumberOfSections(#LEVEL_DATA.worlds)
  for i, world in ipairs(LEVEL_DATA.worlds) do
    self.gridView:setNumberOfRowsInSection(i, #world.levels)
  end

  -- Set gridview config
  self.gridView:setCellPadding(CELL_PADDING_H, CELL_PADDING_H, CELL_PADDING_V, CELL_PADDING_V)
  self.gridView:setContentInset(CELL_INSETS, CELL_INSETS, CELL_INSETS, CELL_INSETS)
  self.gridView:setSectionHeaderHeight(48)
  self.gridView:setNumberOfColumns(1)
  self.gridView.scrollCellsToCenter = false -- [Franch] NOTE: See note in `animateSelectionChange()`.

  -- Set animator

  self.animatorGridCell = gfx.animator.new(CELL_FILL_ANIM_SPEED, 0, CELL_WIDTH, pd.easingFunctions.inOutQuad)

  -- Local gridview function overrides

  self.gridView.drawSectionHeader = function(...) self:drawSectionHeader(...) end
  self.gridView.drawCell = function(...) self:drawCell(...) end
end

---
--- Public/API methods
---

--- Selection Methods: Automatically animated if selection has changed.

function MenuGridView:selectNextRow()
  animateSelectionChange(
    self,
    self.gridView.selectNextRow,
    false,
    true,
    true
  )
end

function MenuGridView:selectPreviousRow()
  animateSelectionChange(
    self,
    self.gridView.selectPreviousRow,
    false,
    true,
    true
  )
end

function MenuGridView:setSelection(section, row)
  animateSelectionChange(
    self,
    self.gridView.setSelection,
    section,
    row,
    1
  )
end

-- Draw Methods

function MenuGridView:drawSectionHeader(section, x, y, width, height)
	local fontHeight = gfx.getSystemFont():getHeight()
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawTextAligned("*WORLD " .. section .. "*", x + width / 2, y + (height/2 - fontHeight/2) + 2, kTextAlignment.center)
end

function MenuGridView:drawCell(section, row, _, selected, x, y, width, height)
  gfx.setDitherPattern(0.1, gfx.image.kDitherTypeDiagonalLine)
  if selected then
    gfx.fillRoundRect(x, y, self.animatorGridCell:currentValue(), CELL_HEIGHT, 10)
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
