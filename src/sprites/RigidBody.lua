class("RigidBody").extends(AnimatedSprite)

function RigidBody:init(entity, imageTable)
  RigidBody.super.init(self, imageTable)
  self.pos = Vector(entity.position.x, entity.position.y)
  self.velocity = Vector(0, 0)
  self.gravity_mult = 1
end
