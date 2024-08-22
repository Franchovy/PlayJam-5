local pd <const> = playdate
local gmt <const> = pd.geometry
local gfx <const> = pd.graphics

local DEBUG_PRINT = false

class("RigidBody").extends(AnimatedSprite)

function RigidBody:init(entity, imageTable)
  RigidBody.super.init(self, imageTable)

  self.velocity = gmt.vector2D.new(0, 0)
  self.g_mult = 1
  self.inv_mass = 0.4
  self.restitution = 0
  self.static_friction = 0
  self.dynamic_friction = .12
  self.air_friction = .14
  self.ground_friction = .3
  self.maxFallSpeed = 13
  self.maxConveyorSpeed = 6
  self.onParent = false

  self.DEBUG_SHOULD_PRINT_VELOCITY = false
end

function RigidBody:collisionResponse(_)
  return gfx.sprite.kCollisionTypeSlide
end

-- override this in subclasses to handle collisions outside of basic physics
function RigidBody:handleCollisionExtra(collisionData)
end

function RigidBody:exitParent()
  return false
end

--- Skips physics handling for one frame.
function RigidBody:skipPhysicsHandling()
  self.shouldSkipPhysicsHandling = true
end

function RigidBody:update()
  if DEBUG_PRINT then print("RigidBody:update() for: ", getmetatable(self).className) end
  RigidBody.super.update(self)

  if self.shouldSkipPhysicsHandling then
    self.shouldSkipPhysicsHandling = nil

    return
  end

  local exitParent = self:exitParent()

  -- calculate new position by adding velocity to current position
  local newPos
  if self.onParent and self.parent and not exitParent then
    newPos = gmt.vector2D.new(self.parent.x, self.parent.y - self.parent.height/2) + (self.velocity * _G.delta_time)
  else
    newPos = gmt.vector2D.new(self.x, self.y) + (self.velocity * _G.delta_time)
  end

  local newX, newY = newPos:unpack()
  local currentVX, _ = self.velocity:unpack()

  local _, _, sdkCollisions = self:moveWithCollisions(newX, newY)

  local parentFound = false
  local groundFound = false

  for _, c in pairs(sdkCollisions) do
    local other = c.other
    local tag = other:getTag()
    local normal = c.normal
    local _, normalY = normal:unpack()

    if DEBUG_PRINT then print("Found collision with: ", getmetatable(other).className) end

    if normalY == -1 and PROPS.Ground[tag] and not groundFound then
      groundFound = true
    end

    if groundFound and PROPS.Parent[tag] and not parentFound and not exitParent then
      parentFound = true
      self.parent = other
    end

    if tag == TAGS.ConveyorBelt and normalY == -1 and math.abs(currentVX) < self.maxConveyorSpeed then
      if DEBUG_PRINT then print("Applying collision belt logic") end

      local conveyorSpeed = other:getAppliedSpeed()
      self.velocity = self.velocity + (gmt.vector2D.new(conveyorSpeed, 0) * _G.delta_time)

      self.DEBUG_SHOULD_PRINT_VELOCITY = DEBUG_PRINT
    end

    self:handleCollisionExtra(c)
  end

  self.onGround = groundFound
  self.onParent = parentFound

  if self.DEBUG_SHOULD_PRINT_VELOCITY then print(self.velocity) end

  -- incorporate gravity

  if not groundFound then
    -- Adds gravity vector to current velocity

    self.velocity = self.velocity + (gmt.vector2D.new(0, 1) * _G.delta_time) * self.g_mult
  elseif groundFound then
    -- Resets velocity (still applying gravity)

    local dx, _ = self.velocity:unpack()
    self.velocity = gmt.vector2D.new(dx, self.g_mult * _G.delta_time)
  end

  -- incorporate any in-air drag
  if not groundFound and currentVX ~= 0 then
    self.velocity:addVector(gmt.vector2D.new((-currentVX * self.air_friction) * _G.delta_time, 0))
  end

  -- incorporate any ground friction
  if groundFound and currentVX ~= 0 then
    self.velocity:addVector(gmt.vector2D.new((-currentVX * self.ground_friction) * _G.delta_time, 0))
  end

  if DEBUG_PRINT then print("RigidBody:update() finished.") end
end
