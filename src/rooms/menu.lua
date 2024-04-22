local pd <const> = playdate
local sound <const> = pd.sound
local gfx <const> = pd.graphics

local spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")

class("Menu").extends(Room)

local imageBackground <const> = gfx.image.new("assets/images/menu2")
local spriteBackground = gfx.sprite.new(imageBackground)
local sceneManager
local fileplayer

function Menu:enter(previous, inFileplayer)
  -- Set sceneManager reference
  sceneManager = self.manager

  -- fileplayer input
  if inFileplayer then
    fileplayer = inFileplayer
  end

  -- Add background image

  spriteBackground:add()
  spriteBackground:setCenter(0, 0)
  spriteBackground:moveTo(0, 0)

  -- Music

  if not fileplayer then
    fileplayer = assert(pd.sound.fileplayer.new("assets/music/menu"))
  end

  fileplayer:play()
end

function Menu:update(dt)
  -- print("Menu update!")
end

function Menu:leave(next, ...)
  -- destroy entities and cleanup resources
  spriteBackground:remove()

  -- Music
  if next.super.className == "Game" then
    fileplayer:stop()
  end
end

function Menu:draw()
  -- draw the level
end

function Menu:AButtonDown()
  local data = playdate.datastore.read()
  if data then
    sceneManager.scenes.currentGame = Game(data.LEVEL)
  else
    sceneManager.scenes.currentGame = Game(0)
  end
  spButton:play(1)
  sceneManager:enter(sceneManager.scenes.currentGame)
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
  sceneManager:enter(GameComplete(fileplayer))
end
