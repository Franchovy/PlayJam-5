local pd <const> = playdate
local sound <const> = pd.sound
local gfx <const> = pd.graphics

-- Constants / Assets

local imageSpriteTitle <const> = gfx.image.new("assets/images/title"):invertedImage()
local imageSpriteRobot <const> = gfx.imagetable.new(assets.imageTables.player)
local spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")

-- Local Variables

local spriteTitle
local spriteRobot
local spriteContinueButton
local spriteSelectLevelButton
local sceneManager


local timerTitleAnimation
local blinkerPressStart

-- Level Selection

class("Start").extends(Room)

function Start:enter(previous, inFileplayer)
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
  spriteRobot:addState("placeholder-name", 9, 12, { tickStep = 2 }).asDefault()
  spriteRobot:add()
  spriteRobot:moveTo(200, 130)
  spriteRobot:playAnimation()

  spriteContinueButton = gfx.sprite.new()
  spriteSelectLevelButton = gfx.sprite.new()
  self:setStartLabelText("PRESS A TO RESUME")
  self:setSecondaryLabelText("PRESS B TO SELECT LEVEL")

  spriteContinueButton:add()
  spriteContinueButton:moveTo(200, 180)

  spriteSelectLevelButton:add()
  spriteSelectLevelButton:moveTo(200, 200)

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

function Start:setStartLabelText(text)
  assert(text and type(text) == "string")

  local textImage = gfx.imageWithText(text, 300, 80, nil, nil, nil, kTextAlignment.center)

  spriteContinueButton:setImage(textImage:invertedImage())
end

function Start:setSecondaryLabelText(text)
  assert(text and type(text) == "string")

  local textImage = gfx.imageWithText(text, 300, 120, nil, nil, nil, kTextAlignment.center)

  spriteSelectLevelButton:setImage(textImage:invertedImage())
end

function Start:leave(next, ...)
  -- destroy entities and cleanup resources

  spriteTitle:remove()
  spriteRobot:remove()
  spriteContinueButton:remove()
  spriteSelectLevelButton:remove()

  -- Music

  if next.super.className == "Game" then
    fileplayer:stop()
  end

  -- Start animation timer

  timerTitleAnimation:remove()
  blinkerPressStart:remove()

  timerTitleAnimation = nil
end

function Start:AButtonDown()
  local world, level = MemoryCard.getLastPlayed()
  local levelFile = ReadFile.getLevel(world, level)
  if levelFile then
    LDtk.load(assets.path.levels..levelFile)
    spButton:play(1)
    MemoryCard.setLastPlayed(world, level)
    sceneManager.scenes.currentGame = Game(0)
    sceneManager:enter(sceneManager.scenes.currentGame)
  end
end

function Start:BButtonDown()
  sceneManager:enter(sceneManager.scenes.menu)
end
