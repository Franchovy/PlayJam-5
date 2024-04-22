local pd <const> = playdate
local sound <const> = pd.sound
local gfx <const> = pd.graphics

local spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")

class("Menu").extends(Room)

local imagetableBackground <const> = gfx.imagetable.new("assets/images/menu2")
local spriteBackground
local imagetableRobot = gfx.imagetable.new("assets/images/boseki")
local spriteRobot
local sceneManager
local fileplayer

function Menu:enter(previous, inFileplayer)
  -- Set sceneManager reference
  sceneManager = self.manager

  -- fileplayer input
  if inFileplayer then
    fileplayer = inFileplayer
  end

  -- Read progress from file
  local data = pd.datastore.read()
  local spriteImage
  if not data then
    spriteImage = imagetableBackground[1]
  elseif data.GAMECOMPLETE then
    spriteImage = imagetableBackground[4]
  elseif data.LEVEL then
    spriteImage = imagetableBackground[3]
  elseif data.NOTFIRSTPLAYTHROUGH then
    spriteImage = imagetableBackground[2]
  end

  spriteBackground = gfx.sprite.new(spriteImage)
  spriteRobot = AnimatedSprite.new(imagetableRobot)
  spriteRobot:addState("placeholder-name", 5, 6, { tickStep = 2 }).asDefault()

  -- Add background image

  spriteBackground:add()
  spriteBackground:setCenter(0, 0)
  spriteBackground:moveTo(0, 0)

  spriteRobot:add()
  spriteRobot:moveTo(180, 100)
  spriteRobot:playAnimation()

  -- Music

  if not fileplayer then
    if not data or not data.GAMECOMPLETE then
      fileplayer = assert(pd.sound.fileplayer.new("assets/music/menu"))
    else
      fileplayer = assert(pd.sound.fileplayer.new("assets/music/menu-credits"))
    end
  end

  fileplayer:play()
end

function Menu:update(dt)
  -- print("Menu update!")
end

function Menu:leave(next, ...)
  -- destroy entities and cleanup resources
  spriteBackground:remove()
  spriteRobot:remove()

  -- Music
  if next.super.className == "Game" then
    fileplayer:stop()
  end
end

function Menu:draw()
  -- draw the level
end

function Menu:AButtonDown()
  spButton:play(1)

  local data = playdate.datastore.read()

  if not data then
    data = {
      NOTFIRSTPLAYTHROUGH = true
    }

    pd.datastore.write(data)

    sceneManager:enter(HowTo(), fileplayer, true)
  else
    if data.LEVEL then
      sceneManager.scenes.currentGame = Game(data.LEVEL - 1)
    else
      sceneManager.scenes.currentGame = Game(0)
    end

    sceneManager:enter(sceneManager.scenes.currentGame)
  end
end

function Menu:rightButtonDown()
  spButton:play(1)
  sceneManager:enter(LevelSelect(fileplayer))
end

function Menu:BButtonDown()
  spButton:play(1)
  sceneManager.scenes.howto = HowTo()
  sceneManager:push(sceneManager.scenes.howto)
end

function Menu:leftButtonDown()
  spButton:play(1)
  sceneManager:push(GameComplete(), true)
end
