local gfx <const> = playdate.graphics

class("Door").extends(playdate.graphics.sprite)

local imageDoor <const> = gfx.image.new("assets/images/door")

function Door:init()
    Door.super.init(self, imageDoor)

    self:setTag(TAGS.Door)
end
