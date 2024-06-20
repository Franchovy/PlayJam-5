local pd <const> = playdate
local sound <const> = pd.sound
local gfx <const> = pd.graphics

local spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")

class("Menu").extends(Room)

local imageSpriteTitle = gfx.image.new("assets/images/title"):invertedImage()
local spriteTitle
local imageSpriteRobot = gfx.imagetable.new("assets/images/boseki")
local spriteRobot
local spritePressStart
local sceneManager
local fileplayer

local timerTitleAnimation
local blinkerPressStart

function Menu:enter(previous, inFileplayer)
  -- Set sceneManager reference
  sceneManager = self.manager

  -- fileplayer input
  if inFileplayer then
    fileplayer = inFileplayer
  end

  -- Draw background sprites

  spriteTitle = gfx.sprite.new(imageSpriteTitle)
  spriteTitle:add()
  spriteTitle:moveTo(200, 70)

  spriteRobot = AnimatedSprite.new(imageSpriteRobot)
  spriteRobot:addState("placeholder-name", 5, 6, { tickStep = 2 }).asDefault()
  spriteRobot:add()
  spriteRobot:moveTo(200, 130)
  spriteRobot:playAnimation()

  spritePressStart = gfx.sprite.spriteWithText("PRESS A TO START", 280, 70)
  spritePressStart:setImage(spritePressStart:getImage():invertedImage())

  spritePressStart:add()
  spritePressStart:moveTo(200, 180)

  -- Reset draw offset

  gfx.setDrawOffset(0, 0)

  -- Music

  if not fileplayer then
    fileplayer = assert(pd.sound.fileplayer.new("assets/music/03_Factory"))
  end

  fileplayer:play()

  -- Little fancy animation(s)

  local animationOffset = 10
  local showDelay = 15
  local hideDelay = 5
  local loopDelay = 2000

  timerTitleAnimation = playdate.timer.new(loopDelay, function()
    spriteTitle:remove()

    -- Title animation

    playdate.timer.performAfterDelay(hideDelay, function()
      if not timerTitleAnimation then return end -- escape if scene has exited

      spriteTitle:moveBy(-animationOffset, animationOffset)
      spriteTitle:add()

      playdate.timer.performAfterDelay(showDelay, function()
        spriteTitle:remove()

        playdate.timer.performAfterDelay(hideDelay, function()
          if not timerTitleAnimation then return end -- escape if scene has exited

          spriteTitle:moveBy(animationOffset * 2, -animationOffset * 2)
          spriteTitle:add()

          playdate.timer.performAfterDelay(showDelay, function()
            spriteTitle:remove()

            playdate.timer.performAfterDelay(hideDelay, function()
              if not timerTitleAnimation then return end -- escape if scene has exited

              spriteTitle:moveBy(-animationOffset, animationOffset)
              spriteTitle:add()
            end)
          end)
        end)
      end)
    end)
  end)

  timerTitleAnimation.repeats = true

  -- Press start button blinker

  blinkerPressStart = gfx.animation.blinker.new(1200, 80, true)
  blinkerPressStart:startLoop()
end

local blinkerWasActive = false

function Menu:update()
  -- Update "Press start" sprite if blinker has toggled.
  if blinkerWasActive ~= blinkerPressStart.on then
    -- Keep track of previous state
    blinkerWasActive = blinkerPressStart.on

    if blinkerWasActive then
      spritePressStart:add()
    else
      spritePressStart:remove()
    end
  end
end

function Menu:leave(next, ...)
  -- destroy entities and cleanup resources

  spriteTitle:remove()
  spriteRobot:remove()
  spritePressStart:remove()

  -- Music

  if next.super.className == "Game" then
    fileplayer:stop()
  end

  -- Menu animation timer

  timerTitleAnimation:remove()
  blinkerPressStart:remove()

  timerTitleAnimation = nil
end

function Menu:AButtonDown()
  spButton:play(1)

  sceneManager.scenes.currentGame = Game(0)
  sceneManager:enter(sceneManager.scenes.currentGame)
end
