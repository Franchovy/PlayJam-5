local gfx <const> = playdate.graphics

class("Box").extends(gfx.sprite)

function Box:init(entity)
    Box.super.init(self, entity, gfx.image.new("assets/images/box"))

    self:setTag(TAGS.Box)

    self.rigidBody = RigidBody(self)
end

function Box:update()
    self.rigidBody:update()
end

function ConveyorBelt:collisionResponse(_)
  return gfx.sprite.kCollisionTypeSlide
end
