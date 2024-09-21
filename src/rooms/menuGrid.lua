local pd <const> = playdate
local gfx <const> = pd.graphics
local ui <const> = pd.ui

local CELL_HEIGHT <const> = 110
local CELL_INSETS <const> = 5
local CELL_PADDING_V <const> = 8
local CELL_PADDING_H = 5

local CELL_FILL_ANIM_SPEED <const> = 800

CELL_WIDTH = 400 - (CELL_INSETS * 2) - (CELL_PADDING_H * 2)

class ("MenuGrid").extends()

local a

function MenuGrid.new()
  a = gfx.animator.new(CELL_FILL_ANIM_SPEED, 0, CELL_WIDTH, playdate.easingFunctions.inOutQuad)
  local gridView = ui.gridview.new(0, CELL_HEIGHT)
  gridView:setNumberOfSections(4)
  gridView:setNumberOfRows(4, 4, 4, 4)
  gridView:setCellPadding(CELL_PADDING_H, CELL_PADDING_H, CELL_PADDING_V, CELL_PADDING_V)
  gridView:setContentInset(CELL_INSETS, CELL_INSETS, CELL_INSETS, CELL_INSETS)
  gridView:setSectionHeaderHeight(48)
  gridView:setNumberOfColumns(1)
  gridView.drawSectionHeader = MenuGrid.drawSectionHeader
  gridView.drawCell = MenuGrid.drawCell
  return gridView
end

function MenuGrid.resetAnimator(section, row)
  -- TODO: total/rescued not tracked currently, put this back for width
  local total, rescued = MemoryCard.getLevelCompletion(section, row);
  local width = (rescued / total) * CELL_WIDTH
  a = gfx.animator.new(CELL_FILL_ANIM_SPEED, 0, CELL_WIDTH, playdate.easingFunctions.inOutQuad)
end

function MenuGrid.drawSectionHeader(_, section, x, y, width, height)
	local fontHeight = gfx.getSystemFont():getHeight()
  gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawTextAligned("*WORLD " .. section .. "*", x + width / 2, y + (height/2 - fontHeight/2) + 2, kTextAlignment.center)
end

function MenuGrid.drawCell(_, section, row, _, selected, x, y, width, height)
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

