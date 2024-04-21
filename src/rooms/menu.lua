local pd <const> = playdate
local gfx <const> = pd.graphics

class("Menu").extends(Room)

local imageBackground <const> = gfx.image.new("assets/images/menu")
local spriteBackground = gfx.sprite.new(imageBackground)
local sceneManager
local fileplayer

function Menu:enter(previous, ...)
    -- Set sceneManager reference
    sceneManager = self.manager

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
    fileplayer:stop()
end

function Menu:draw()
    -- draw the level
end

function Menu:AButtonDown()
    sceneManager:enter(Game(0))
end

function Menu:BButtonDown()
  sceneManager.scenes.howto = HowTo(sceneManager)
  sceneManager:push(sceneManager.scenes.howto)
end
