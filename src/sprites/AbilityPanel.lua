local pd <const> = playdate
local gfx <const> = pd.graphics
local gmt <const> = pd.geometry

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

local panelHiddenY <const> = -60
local buttonHiddenY <const> = -60
local panelShownY <const> = 0
local buttonShownY <const> = 12

local buttonOneX <const> = 16
local buttonOnePointsShow = gmt.polygon.new(buttonOneX, buttonHiddenY, buttonOneX, buttonShownY)
local buttonOnePointsHide = gmt.polygon.new(buttonOneX, buttonShownY, buttonOneX, buttonHiddenY)
local buttonTwoX <const> = 48
local buttonTwoPointsShow = gmt.polygon.new(buttonTwoX, buttonHiddenY, buttonTwoX, buttonShownY)
local buttonTwoPointsHide = gmt.polygon.new(buttonTwoX, buttonShownY, buttonTwoX, buttonHiddenY)
local buttonThreeX <const> = 80
local buttonThreePointsShow = gmt.polygon.new(buttonThreeX, buttonHiddenY, buttonThreeX, buttonShownY)
local buttonThreePointsHide = gmt.polygon.new(buttonThreeX, buttonShownY, buttonThreeX, buttonHiddenY)

function AbilityPanel:init()
    AbilityPanel.super.init(self, imagePanel)
    self:moveTo(0, panelHiddenY)
    self:add()

    spriteOne:moveTo(16, buttonHiddenY)
    spriteOne:setZIndex(100)
    spriteOne:add()
    spriteTwo:moveTo(48, buttonHiddenY)
    spriteTwo:setZIndex(100)
    spriteTwo:add()
    spriteThree:moveTo(80, buttonHiddenY)
    spriteThree:setZIndex(100)
    spriteThree:add()

    spriteOne:setImage(self:imageForItem("right"))
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

function AbilityPanel:gameUpdate()
  if pd.buttonJustPressed(pd.kButtonB) then
    self:animate(true)
  elseif pd.buttonJustReleased(pd.kButtonB) then
    self:animate(false)
  end
end

function AbilityPanel:animate(show)
  local easing = pd.easingFunctions.inBack
  local duration = 250

  if show then
    local panelPoints = gmt.polygon.new(0, panelHiddenY, 0, panelShownY)
    self:setAnimator(gfx.animator.new(duration, panelPoints, easing))
    spriteOne:setAnimator(gfx.animator.new(duration, buttonOnePointsShow, easing))
    spriteTwo:setAnimator(gfx.animator.new(duration, buttonTwoPointsShow, easing))
    spriteThree:setAnimator(gfx.animator.new(duration, buttonThreePointsShow, easing))
  else
    local delay = 150
    local panelPoints = gmt.polygon.new(0, panelShownY , 0, panelHiddenY)
    self:setAnimator(gfx.animator.new(duration, panelPoints, easing, delay))
    spriteOne:setAnimator(gfx.animator.new(duration, buttonOnePointsHide, easing, delay))
    spriteTwo:setAnimator(gfx.animator.new(duration, buttonTwoPointsHide, easing, delay))
    spriteThree:setAnimator(gfx.animator.new(duration, buttonThreePointsHide, easing, delay))
  end
end

function AbilityPanel:addItem(item)
  if self.abilitiesCount == 3 then
    spriteOne:setImage(spriteTwo:getImage())
    spriteTwo:setImage(spriteThree:getImage())
    spriteThree:setImage(self:imageForItem(item))
  else
    self.abilitiesCount = self.abilitiesCount + 1

    local image = self:imageForItem(item)
    if self.abilitiesCount == 1 then
      spriteOne:setImage(image)
    elseif self.abilitiesCount == 2 then
      spriteTwo:setImage(image)
    elseif self.abilitiesCount == 3 then
      spriteThree:setImage(image)
    end
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

function AbilityPanel:cleanUp()
  local emptyImage = gfx.image.new(1, 1)
  spriteOne:setImage(emptyImage)
  spriteTwo:setImage(emptyImage)
  spriteThree:setImage(emptyImage)
  self:remove()
end

function AbilityPanel:removeRightMost()
  if self.abilitiesCount == 1 then
    return
  end

  local emptyImage = gfx.image.new(1, 1)

  if self.abilitiesCount == 2 then
    spriteTwo:setImage(emptyImage)
  elseif self.abilitiesCount == 3 then
    spriteThree:setImage(emptyImage)
  end

  self.abilitiesCount = self.abilitiesCount - 1;

end
