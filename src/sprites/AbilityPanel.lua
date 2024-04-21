local pd <const> = playdate
local gfx <const> = pd.graphics

class("AbilityPanel").extends(pd.graphics.sprite)

local imageUp <const> = gfx.image.new("assets/images/Up")
local imageDown <const> = gfx.image.new("assets/images/Down")
local imageLeft <const> = gfx.image.new("assets/images/Left")
local imageRight <const> = gfx.image.new("assets/images/Right")
local imageA <const> = gfx.image.new("assets/images/A")
local imagePanel <const> = gfx.image.new("assets/images/panel")

local spriteOne = gfx.sprite.new()
local spriteTwo = gfx.sprite.new()
local spriteThree = gfx.sprite.new()
local spriteFour = gfx.sprite.new()
local spriteFive = gfx.sprite.new()


function AbilityPanel:init(startingItem)
    AbilityPanel.super.init(self, imagePanel)
    self:add()

    spriteOne:moveTo(16, 12)
    spriteOne:setZIndex(100)
    spriteOne:add()
    spriteTwo:moveTo(48, 12)
    spriteTwo:setZIndex(100)
    spriteTwo:add()
    spriteThree:moveTo(80, 12)
    spriteThree:setZIndex(100)
    spriteThree:add()
    spriteFour:moveTo(102, 12) 
    spriteFour:setZIndex(100)
    spriteFour:add()
    spriteFive:moveTo(120, 12)
    spriteFive:setZIndex(100)
    spriteFive:add()

    spriteOne:setImage(self:imageForItem(startingItem))
    self.abilitiesCount = 1
    self:setZIndex(99)
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
  self.abilitiesCount = self.abilitiesCount + 1

  local image = self:imageForItem(item);
  if self.abilitiesCount == 1 then
    spriteOne:setImage(image)
  elseif self.abilitiesCount == 2 then
    spriteTwo:setImage(image)
  elseif self.abilitiesCount == 3 then
    spriteThree:setImage(image)
  elseif self.abilitiesCount == 4 then
    spriteFour:setImage(image)
  elseif self.abilitiesCount == 5 then
    spriteFive:setImage(image)
  end
end

function AbilityPanel:imageForItem(item)
  item = string.lower(item)
  if item == "up" then
    return imageUp
  elseif item == "down" then
    return imageDown
  elseif item == "left" then
    return imageLeft
  elseif item == "right" then
    return imageRight
  elseif item == "a" then
    return imageA
  end
end

function AbilityPanel:destroy()
  local emptyImage =gfx.image.new(1, 1)
  spriteOne:setImage(emptyImage)
  spriteTwo:setImage(emptyImage)
  spriteThree:setImage(emptyImage)
  spriteFour:setImage(emptyImage)
  spriteFive:setImage(emptyImage)
  self:remove()
end
