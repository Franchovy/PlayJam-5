local gfx <const> = playdate.graphics

local imageBackground = gfx.image.new("assets/images/background")

class("Background").extends(gfx.sprite)

function Background:init()
    Background.super.init(self, imageBackground)

    self:setCenter(0, 0)
    self:moveTo(0, 0)
    self:setZIndex(-100)
    self:setIgnoresDrawOffset(true)
    self:add()
end
