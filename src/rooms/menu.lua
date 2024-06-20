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

  -- Music

  if not fileplayer then
    fileplayer = assert(pd.sound.fileplayer.new("assets/music/menu"))
  end

  fileplayer:play()
end

function Menu:leave(next, ...)
  -- destroy entities and cleanup resources
  spriteTitle:remove()
  spriteRobot:remove()

  -- Music
  if next.super.className == "Game" then
    fileplayer:stop()
  end
end

function Menu:AButtonDown()
  spButton:play(1)

  sceneManager.scenes.currentGame = Game(0)
  sceneManager:enter(sceneManager.scenes.currentGame)
end
