local pd <const> = playdate
local gfx <const> = pd.graphics

class("RigidBody").extends(AnimatedSprite)

function RigidBody:init(entity, imageTable)
  RigidBody.super.init(self, imageTable)
  self.pos = Vector(entity.position.x, entity.position.y)
  self.velocity = Vector(0, 0)
  self.gravity_mult = 1
end

function RigidBody:update()
  -- calculate new position by adding velocity to current position
  local newPos = self.pos:add(self.velocity)

  self.velocity = self.velocity:add(Vector(0, 1))
  local actualX, actualY = self:moveWithCollisions(newPos.x, newPos.y)
  self.pos = Vector(actualX, actualY)
end

function RigidBody:setVelocity(x, y)
  self.velocity = Vector(x, y)
end

function RigidBody:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Wall or tag == TAGS.ConveyorBelt or tag == TAGS.Box then
        return gfx.sprite.kCollisionTypeSlide
    else
        return gfx.sprite.kCollisionTypeOverlap
    end
end

