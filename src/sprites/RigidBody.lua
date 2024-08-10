local pd <const> = playdate
local gmt <const> = pd.geometry
local gfx <const> = pd.graphics

local complexCollision = false

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

-- override this in subclasses to handle collisions outside of basic physics
function RigidBody:handleCollisionExtra(collisionData)
end

function RigidBody:update()
  if DEBUG_PRINT then print("RigidBody:update() for: ", getmetatable(self).className) end
  RigidBody.super.update(self)

  -- calculate new position by adding velocity to current position
  local newPos = gmt.vector2D.new(self.x, self.y) + (self.velocity * _G.delta_time)
  if self.onParent and self.parent then
    newPos = newPos + self.parent.velocity / 2
  end

  local newX, newY = newPos:unpack()
  local currentVX, currentVY = self.velocity:unpack()

  local _, _, sdkCollisions = self:moveWithCollisions(newX, newY)

  local parentFound = false
  local groundFound = false

  for _, c in pairs(sdkCollisions) do
    local other = c.other
    local tag = other:getTag()
    local normal = c.normal
    local _, normalY = normal:unpack()

    if DEBUG_PRINT then print("Found collision with: ", getmetatable(other).className) end

    if complexCollision and tag ~= TAGS.Player then
      self:checkCollision(other)
    end

    if normalY == -1 and PROPS.Ground[tag] then
      groundFound = true
    end

    if groundFound and PROPS.Parent[tag] then
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

function RigidBody:checkCollision(other)
  if self.onParent and self.parent == other then return end

  local normal = gmt.vector2D.new(0, 0)
  local pen = 0.0

  local yOverlap = 0
  local yVector = gmt.vector2D.new(0, 0)

  -- other is below self
  if self.y < other.y then
    yVector = gmt.vector2D.new(0, 1)
    yOverlap = (self.y + self.height) - (other.y)
    -- other is above self
  else
    yVector = gmt.vector2D.new(0, -1)
    yOverlap = self.y - other.y
  end

  local xOverlap = 0
  local xVector = gmt.vector2D.new(0, 0)

  if self.x < other.x then
    xVector = gmt.vector2D.new(1, 0)
    xOverlap = (other.x + other.width) - (self.x)
  else
    xVector = gmt.vector2D.new(-1, 0)
    xOverlap = (self.x + self.width) - other.x
  end

  if yOverlap < xOverlap then
    local dx, dy = yVector:unpack()
    normal = gmt.vector2D.new(dx, dy)
    pen = yOverlap
  else
    local dx, dy = xVector:unpack()
    normal = gmt.vector2D.new(dx, dy)
    pen = xOverlap
  end

  local other_inv_mass = 0
  if other["inv_mass"] then
    other_inv_mass = other.inv_mass
  end

  self:collide(other, normal, other_inv_mass)

  -- positional correction for sinking objects
  local percent = 0.2
  local slop = .1
  local correction = normal * (math.max(pen - slop, 0) / (self.inv_mass + other_inv_mass) * percent)
  local newSelfPos = gmt.vector2D.new(self.x, self.y) + (-correction * self.inv_mass)
  self:moveTo(newSelfPos.x, newSelfPos.y)
  local newOtherPos = gmt.vector2D.new(other.x, other.y) + (correction * other_inv_mass)
  other:moveTo(newOtherPos.x, newOtherPos.y)
end

function RigidBody:collisionResponse(_)
  return gfx.sprite.kCollisionTypeSlide
end

function RigidBody:collide(other, normal, other_inv_mass)
  local inv_mass_sum = self.inv_mass + other_inv_mass

  if inv_mass_sum == 0 then
    self.velocity = gmt.vector2D.new(0, 0)
    other.velocity = gmt.vector2D.new(0, 0)
    return;
  end

  local relative_velocity = gmt.vector2D.new(0, 0)
  if other["velocity"] then
    relative_velocity = other.velocity - self.velocity
  else
    relative_velocity = self.velocity:scaledBy(-1)
  end

  -- put it in terms of the collision normal direction
  local velocity_along_normal = relative_velocity * normal

  -- objects are not approaching each other
  if velocity_along_normal > 0 then
    return
  end

  -- calculate restitution
  local e = self.restitution
  if other["restitution"] then
    e = math.min(self.restitution, other.restitution)
  end

  -- calculate impulse scalar
  local j = (-1 * (1 + e)) * velocity_along_normal
  j = j / inv_mass_sum;

  -- apply impulse
  local impulse = normal * j
  if j >= 1 then
    self.velocity = self.velocity - (impulse * self.inv_mass)
    if other["velocity"] then
      other.velocity = other.velocity - (impulse * other_inv_mass)
    end
  end

  -- BEGIN FRICTION CALC

  -- Re-calculate relative velocity after normal impulse
  -- is applied (impulse from first article, this code comes
  -- directly thereafter in the same resolve function)
  if other["velocity"] then
    relative_velocity = other.velocity - self.velocity
  else
    relative_velocity = self.velocity:scaledBy(-1)
  end

  -- Solve for the tangent vector
  local dot = relative_velocity * normal
  local dot_x_normal = normal * dot

  local rvx, rvy = relative_velocity:unpack()
  local dotx, doty = dot_x_normal:unpack()

  if rvx == dotx and rvy == doty then
    return
  end
  local tangent = relative_velocity - dot_x_normal
  tangent = tangent:normalized()

  -- Solve for magnitude to apply along the friction vector
  local jt = -relative_velocity * tangent
  jt = jt / inv_mass_sum

  -- PythagoreanSolve = A^2 + B^2 = C^2, solving for C given A and B
  -- Use to approximate mu given friction coefficients of each body
  local other_static_friction = 0
  local other_dynamic_friction = 0
  if other["static_friction"] then
    other_static_friction = other.static_friction
  end
  if other["dynamicFriction"] then
    other_dynamic_friction = other.dynamic_friction
  end
  local mu = math.sqrt((self.static_friction * self.static_friction) + (other_static_friction * other_static_friction))

  -- Clamp magnitude of friction and create impulse vector
  local friction_impulse = gmt.vector2D.new(0, 0)

  if math.abs(jt) < j * mu then
    friction_impulse = tangent * jt
  else
    local dynamicFriction = math.sqrt((self.dynamic_friction * self.dynamic_friction) +
      (other_dynamic_friction * other_dynamic_friction))
    friction_impulse = tangent * (-j * dynamicFriction)
  end

  -- Apply
  self.velocity = self.velocity - (friction_impulse * self.inv_mass)
  if other["velocity"] then
    other.velocity = other.velocity + (friction_impulse * other_inv_mass)
  end
end
