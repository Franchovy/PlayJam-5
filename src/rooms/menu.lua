local pd <const> = playdate
local sound <const> = pd.sound
local gfx <const> = pd.graphics

-- Constants / Assets

local spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")
local imageSpriteTitle <const> = gfx.image.new("assets/images/title"):invertedImage()
local imageSpriteRobot <const> = gfx.imagetable.new(assets.imageTables.player)
local imagetableArrows <const> = gfx.imagetable.new(assets.imageTables.menuArrows)

-- Local Variables

local spritesArrows = {}
local spriteTitle
local spriteRobot
local spritePressStart
local sceneManager
local fileplayer

local timerTitleAnimation
local blinkerPressStart

-- Level Selection

local indexLevel = nil
local levels = nil

class("Menu").extends(Room)

function Menu:init(_levels)
  levels = _levels
end

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
  spriteRobot:addState("placeholder-name", 9, 12, { tickStep = 2 }).asDefault()
  spriteRobot:add()
  spriteRobot:moveTo(200, 130)
  spriteRobot:playAnimation()

  for i=1,2 do
    spritesArrows[i] = gfx.sprite.new(imagetableArrows[i])
  end

  spritePressStart = gfx.sprite.new()
  self:setMenuLabelText("PRESS A TO START")

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

function Menu:setMenuLabelText(text)
  assert(text and type(text) == "string")

  local textImage = gfx.imageWithText(text, 300, 80, nil, nil, nil, kTextAlignment.center)

  spritePressStart:setImage(textImage:invertedImage())
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

function Menu:incrementLevelSelectionIndex(increment)
  if not indexLevel then
    indexLevel = 1
  else
    -- Increment
    indexLevel += increment

    -- Loop around if out of range
    if indexLevel > #levels then
      indexLevel = 1
    elseif indexLevel < 1 then
      indexLevel = #levels
    end
  end

  -- Update menu label text

  self:setMenuLabelText(levels[indexLevel])

  -- Move arrows

  local leftArrow = spritesArrows[1]
  leftArrow:moveTo(spritePressStart.x - spritePressStart.width / 2 - 16, spritePressStart.y)
  leftArrow:add()

  local rightArrow = spritesArrows[2]
  rightArrow:moveTo(spritePressStart.x + spritePressStart.width / 2 + 16, spritePressStart.y)
  rightArrow:add()
end

function Menu:AButtonDown()
  if indexLevel then
    -- Start game with level

    LDtk.load(assets.path.levels.. levels[indexLevel])

    spButton:play(1)

    sceneManager.scenes.currentGame = Game(0)
    sceneManager:enter(sceneManager.scenes.currentGame)
  else
    -- Load Level selection

    self:incrementLevelSelectionIndex()
  end
end

function Menu:rightButtonDown()
  self:incrementLevelSelectionIndex(1)
end

function Menu:leftButtonDown()
  self:incrementLevelSelectionIndex(-1)
end