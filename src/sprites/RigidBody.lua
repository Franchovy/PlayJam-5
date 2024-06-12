local pd <const> = playdate
local gmt <const> = pd.geometry
local gfx <const> = pd.graphics

local complexCollision = true
local maxFallSpeed = 13

class("RigidBody").extends(AnimatedSprite)

function RigidBody:init(entity, imageTable)
  RigidBody.super.init(self, imageTable)
  self.velocity = gmt.vector2D.new(0, 0)
  self.inv_mass = 0.4
  self.restitution = 0.4
  self.static_friction = 0
  self.dynamic_friction = .12
end

function RigidBody:update()
  RigidBody.super.update(self)
  -- calculate new position by adding velocity to current position
  local newPos = gmt.vector2D.new(self.x, self.y) + (self.velocity * _G.delta_time)
  local newX, newY = newPos:unpack()

  local _, _, collisions = self:moveWithCollisions(newX, newY)

  local beltFound = false
  local onGround = false

  for _, c in pairs(collisions) do
    local normal = c.normal
    local _, normalY = normal:unpack()
    local other = c.other
    if complexCollision then
      self:checkCollision(other)
    end
    local tag = other:getTag()
    onGround = not onGround and (tag == TAGS.Wall or tag == TAGS.ConveyorBelt) and normalY == -1

    if tag == TAGS.Box and normalY == -1 then -- really basic platform
      self:moveTo(other.x, self.y)
      return
    elseif tag == TAGS.ConveyorBelt and normalY == -1 then
      beltFound = true
      if not self.onBelt then-- only apply belt velocity once
        local dir = other:getDirection()
        if dir == "Right" then
          self.velocity = self.velocity + (gmt.vector2D.new(10, 0) * _G.delta_time)
        elseif dir == "Left" then
          self.velocity = self.velocity + (gmt.vector2D.new(-10, 0) * _G.delta_time)
        end
      end
    end
  end
  self.onBelt = beltFound

  local _, currentVY = self.velocity:unpack()

  if not beltFound then
    self.velocity = gmt.vector2D.new(0, currentVY)
  end

  -- incorporate gravity
  if (complexCollision or not onGround) and currentVY < maxFallSpeed then
    self.velocity = self.velocity + (gmt.vector2D.new(0, 1) * _G.delta_time) * self.g_mult
   elseif not complexCollision and onGround then
    local dx, _ = self.velocity:unpack()
    self.velocity = gmt.vector2D.new(dx, 0)
   end
end

function RigidBody:checkCollision(other)
  if not other["inv_mass"] then
    return
  end

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
    xVector = gmt.vector2D.new(-1, 0)
    xOverlap = (self.x + self.width) - other.x
  else
    xVector = gmt.vector2D.new(1, 0)
    xOverlap = (other.x + other.width) - (self.x)
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

  self:collide(other, normal)

  -- positional correction for sinking objects
  -- local percent = 0.001
  -- local slop = .001
  -- local correction = normal * (math.max(pen - slop, 0 ) / (self.inv_mass + other.inv_mass) * percent)
  -- self.pos = self.pos:addVector(-correction * self.inv_mass)
  -- other.pos = other.pos:add(correction:multiply(other.inv_mass))
end

function RigidBody:collisionResponse(_)
  return gfx.sprite.kCollisionTypeSlide
end

function RigidBody:collide(other, normal)
  local inv_mass_sum = self.inv_mass + other.inv_mass

  if inv_mass_sum == 0 then
    self.velocity = gmt.vector2D.new(0, 0)
    other.velocity = gmt.vector2D.new(0, 0)
    return;
  end

  local relative_velocity = other.velocity - self.velocity

  -- put it in terms of the collision normal direction
  local velocity_along_normal = relative_velocity * normal

  -- objects are not approaching each other
  if velocity_along_normal > 0 then
    return
  end

  -- calculate restitution
  local e = math.min(self.restitution, other.restitution)

  -- calculate impulse scalar
  local j = (-1 * (1 + e)) * velocity_along_normal
  j = j / inv_mass_sum;

  -- apply impulse
  local impulse = normal * j
  if j >= 1 then
    self.velocity = self.velocity - (impulse * self.inv_mass)
    other.velocity = other.velocity - (impulse * other.inv_mass)
  end

  -- BEGIN FRICTION CALC

  -- Re-calculate relative velocity after normal impulse
  -- is applied (impulse from first article, this code comes
  -- directly thereafter in the same resolve function)
  relative_velocity = other.velocity - self.velocity

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
  local mu = math.sqrt((self.static_friction * self.static_friction) + (other.static_friction * other.static_friction))

  -- Clamp magnitude of friction and create impulse vector
  local friction_impulse = gmt.vector2D.new(0, 0)

  if math.abs(jt) < j * mu then
    friction_impulse = tangent * jt
  else
    local dynamicFriction = math.sqrt((self.dynamic_friction * self.dynamic_friction) + (other.dynamic_friction * other.dynamic_friction))
    friction_impulse = tangent * (-j * dynamicFriction)
  end

  -- Apply
  self.velocity = self.velocity - (friction_impulse * self.inv_mass)
  other.velocity = other.velocity + (friction_impulse * other.inv_mass)
end
