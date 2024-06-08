local gfx <const> = playdate.graphics

class("Box").extends(RigidBody)

function Box:init(entity)
    local imageBox = gfx.imagetable.new("assets/images/box")
    Box.super.init(self, entity, imageBox)

    self:setTag(TAGS.Box)

    self:addState("n", 1, 1).asDefault()
    self:playAnimation()
end
