local gfx <const> = playdate.graphics
local sound <const> = playdate.sound

local spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")

class("HowTo").extends(Room)

local storyImage = gfx.image.new("assets/images/howtoplay_story")
local controlsImage = gfx.image.new("assets/images/howtoplay_controls")
local rulesImage = gfx.image.new("assets/images/howtoplay_rules")

local spriteBackground = gfx.sprite.new(storyImage)

local fileplayer
local shouldPlayGame

function HowTo:init()

end

function HowTo:enter(previous, argFileplayer, argShouldPlayGame, ...)
  shouldPlayGame = argShouldPlayGame or false
  fileplayer = argFileplayer

  spriteBackground:add()
  spriteBackground:setCenter(0, 0)
  spriteBackground:moveTo(0, 0)

  self.currentStep = 0
end

function HowTo:AButtonDown()
  spButton:play(1)
  self.currentStep = self.currentStep + 1

  if self.currentStep == 1 then
    spriteBackground:setImage(rulesImage)
  elseif self.currentStep == 2 then
    spriteBackground:setImage(controlsImage)
  else
    spriteBackground:setImage(storyImage)

    if shouldPlayGame then
      fileplayer:stop()

      local sceneManager = Manager.getInstance()
      sceneManager.scenes.currentGame = Game(0)
      sceneManager:enter(sceneManager.scenes.currentGame)
    else
      Manager.getInstance():pop()
    end
  end
end
