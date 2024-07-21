local pd <const> = playdate
local gfx <const> = pd.graphics
local gmt <const> = pd.geometry

class("AbilityPanel").extends(pd.graphics.sprite)

local imagePanel <const> = gfx.image.new(assets.images.hudPanel)
local emptyImage <const> = gfx.image.new(1, 1)

-- Button images (from imagetable)

local imageTableButtons = gfx.imagetable.new(assets.imageTables.buttons)
local imageTableIndexes = {
  [KEYNAMES.Right] = 1,
  [KEYNAMES.Left] = 2,
  [KEYNAMES.Down] = 3,
  [KEYNAMES.Up] = 4,
  [KEYNAMES.A] = 5,
  [KEYNAMES.B] = 6,
}

local items = {}

local spriteOne = gfx.sprite.new()
local spriteTwo = gfx.sprite.new()
local spriteThree = gfx.sprite.new()

local panelHiddenY <const> = -60
local buttonHiddenY <const> = -60
local panelShownY <const> = 0
local buttonShownY <const> = 14

local buttonOneX <const> = 16
local buttonOnePointsShow = gmt.polygon.new(buttonOneX, buttonHiddenY, buttonOneX, buttonShownY)
local buttonOnePointsHide = gmt.polygon.new(buttonOneX, buttonShownY, buttonOneX, buttonHiddenY)
local buttonTwoX <const> = 42
local buttonTwoPointsShow = gmt.polygon.new(buttonTwoX, buttonHiddenY, buttonTwoX, buttonShownY)
local buttonTwoPointsHide = gmt.polygon.new(buttonTwoX, buttonShownY, buttonTwoX, buttonHiddenY)
local buttonThreeX <const> = 68
local buttonThreePointsShow = gmt.polygon.new(buttonThreeX, buttonHiddenY, buttonThreeX, buttonShownY)
local buttonThreePointsHide = gmt.polygon.new(buttonThreeX, buttonShownY, buttonThreeX, buttonHiddenY)

-- Static Reference

local _instance

function AbilityPanel.getInstance() return _instance end

--

function AbilityPanel:init()
  AbilityPanel.super.init(self, imagePanel)
  _instance = self

  self:setCenter(0, 0)
  self:moveTo(0, 0)

  self:add()

  spriteOne:moveTo(buttonOneX, buttonShownY)
  spriteOne:setZIndex(100)
  spriteOne:add()
  spriteTwo:moveTo(buttonTwoX, buttonShownY)
  spriteTwo:setZIndex(100)
  spriteTwo:add()
  spriteThree:moveTo(buttonThreeX, buttonShownY)
  spriteThree:setZIndex(100)
  spriteThree:add()

  self:setIgnoresDrawOffset(true)
  spriteOne:setIgnoresDrawOffset(true)
  spriteTwo:setIgnoresDrawOffset(true)
  spriteThree:setIgnoresDrawOffset(true)

  self.abilitiesCount = 1
  self:setZIndex(99)
end

local _spriteAdd = AbilityPanel.add
function AbilityPanel:add()
  _spriteAdd(self)

  spriteOne:add()
  spriteTwo:add()
  spriteThree:add()
end

function AbilityPanel:shake(shakeTime, shakeMagnitude)
  local shakeTimer = pd.timer.new(shakeTime, shakeMagnitude, 0)

  shakeTimer.updateCallback = function(timer)
    local magnitude = math.floor(timer.value)
    local shakeX = math.random(-magnitude, magnitude)
    local shakeY = math.random(-magnitude, magnitude)
    self:moveTo(self.original_x + shakeX, self.original_y + shakeY)
  end

  shakeTimer.timerEndedCallback = function()
    self:moveTo(self.original_x, self.original_y)
  end
end

function AbilityPanel:addItem(item)
  if self.abilitiesCount == 3 then
    table.remove(items, 1)
    table.insert(items, item)

    self:updateItemImages()
  else
    table.insert(items, item)

    self:updateItemsCount()
    self:updateItemImages()
  end
end

function AbilityPanel:cleanUp()
  self:setItems()

  self:remove()
end

function AbilityPanel:removeRightMost()
  if self.abilitiesCount == 1 then
    items[1] = nil
  elseif self.abilitiesCount == 2 then
    items[2] = nil
  elseif self.abilitiesCount == 3 then
    items[3] = nil
  end

  self:updateItemsCount()
  self:updateItemImages()
end

function AbilityPanel:setItems(item1, item2, item3)
  items[1] = item1
  items[2] = item2
  items[3] = item3

  self:updateItemsCount()
  self:updateItemImages()
end

function AbilityPanel:updateItemsCount()
  self.abilitiesCount = #items
end

function AbilityPanel:updateItemImages()
  spriteOne:setImage(items[1] and imageTableButtons[imageTableIndexes[items[1]]] or emptyImage)
  spriteTwo:setImage(items[2] and imageTableButtons[imageTableIndexes[items[2]]] or emptyImage)
  spriteThree:setImage(items[3] and imageTableButtons[imageTableIndexes[items[3]]] or emptyImage)
end
