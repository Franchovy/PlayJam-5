local gfx <const> = playdate.graphics
local sound <const> = playdate.sound

local spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")

class("HowTo").extends(Room)

local storyImage = gfx.image.new("assets/images/howtoplay_story")
local controlsImage = gfx.image.new("assets/images/howtoplay_controls")
local rulesImage = gfx.image.new("assets/images/howtoplay_rules")

local spriteBackground = gfx.sprite.new(storyImage)

function HowTo:init()

end

function HowTo:enter(previous, ...)
  spriteBackground:add()
  spriteBackground:setCenter(0, 0)
  spriteBackground:moveTo(0, 0)

  self.currentStep = 0
end

function HowTo:AButtonDown()
  spButton:play(1)
  self.currentStep = self.currentStep + 1

  if self.currentStep == 1 then
    spriteBackground:setImage(controlsImage)
  elseif self.currentStep == 2 then
    spriteBackground:setImage(rulesImage)
  else
    spriteBackground:setImage(storyImage)
    Manager.getInstance():pop()
  end
end
