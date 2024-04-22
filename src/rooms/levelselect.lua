local pd <const> = playdate
local sound <const> = pd.sound
local gfx <const> = pd.graphics

local spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")

local gridview = pd.ui.gridview.new(175, 42)
gridview:setContentInset(25, 25, 10, 10)

local padding = 2
local maxLevel = 1

function gridview:drawCell(_, row, column, selected, x, y, width, height)
  local lvl = row
  if column == 1 then
    lvl = (row * 2) - 1
  else
    lvl = row * column
  end

  if maxLevel >= lvl then
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    local cellFont
    if selected then
      cellFont = gfx.font.kVariantBold
      gfx.fillRoundRect(x + padding, y + padding, width - (padding * 2), height - (padding * 2), 8)
      gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    else
      cellFont = gfx.font.kVariantNormal
      gfx.drawRoundRect(x + padding, y + padding, width - (padding * 2), height - (padding * 2), 8)
    end


    local cellText = "Level " .. lvl
    gfx.drawTextInRect(cellText, x, y + 14, width, 20, nil, nil, kTextAlignment.center, gfx.getFont(cellFont))
  end
end

class("LevelSelect").extends(Room)

local sceneManager
local fileplayer

function LevelSelect:init(menuFileplayer)
  fileplayer = menuFileplayer
end

function LevelSelect:enter()
  sceneManager = Manager.getInstance()

  local data = playdate.datastore.read()
  gridview:setNumberOfColumns(2)

  local rows = 1
  if data then
    if data.GAMECOMPLETE then
      maxLevel = 10
    else
      maxLevel = data.LEVEL
    end

    rows = math.ceil(maxLevel / 2)
    if rows == 0 then
      rows = 1
    end
  end
  gridview:setNumberOfRows(rows)
end

function LevelSelect:update()
  gridview:drawInRect(0, 0, 400, 240)
end

function LevelSelect:rightButtonDown()
  spButton:play(1)
  gridview:selectNextColumn(true)
end

function LevelSelect:leftButtonDown()
  spButton:play(1)
  gridview:selectPreviousColumn(true)
end

function LevelSelect:downButtonDown()
  spButton:play(1)
  gridview:selectNextRow(true)
end

function LevelSelect:upButtonDown()
  spButton:play(1)
  gridview:selectPreviousRow(true)
end

function LevelSelect:BButtonDown()
  spButton:play(1)
  sceneManager:enter(sceneManager.scenes.menu)
end

function LevelSelect:AButtonDown()
  local _, row, column = gridview:getSelection()
  local lvl = 0
  if column == 1 then
    lvl = (row * 2) - 1
  else
    lvl = row * column
  end
  if maxLevel >= lvl then
    spButton:play(1)
    sceneManager.scenes.currentGame = Game(lvl - 1)
    sceneManager:enter(sceneManager.scenes.currentGame)

    fileplayer:stop()
  end
end
