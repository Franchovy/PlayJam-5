local gfx <const> = playdate.graphics

class("Menu").extends(Room)

local imageBackground <const> = gfx.image.new("assets/images/menu")
local spriteBackground = gfx.sprite.new(imageBackground)

function Menu:enter(previous, ...)
    spriteBackground:add()
    spriteBackground:setCenter(0, 0)
    spriteBackground:moveTo(0, 0)
end

function Menu:update(dt)
    -- print("Menu update!")
end

function Menu:leave(next, ...)
    -- destroy entities and cleanup resources
    spriteBackground:remove()
end

function Menu:draw()
    -- draw the level
end

function Menu:AButtonDown()
    self.manager:enter(Game())
end
