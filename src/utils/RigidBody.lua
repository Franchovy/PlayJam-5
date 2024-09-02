local pd <const> = playdate
local gmt <const> = pd.geometry
local gfx <const> = pd.graphics

class("RigidBody").extends()

local gravity <const> = 1
local airFriction <const> = .14
local groundFriction <const> = .3

function RigidBody:init(sprite, config)
  self.sprite = sprite

  -- Config

  if config then
    self.gravity = config.gravity or gravity -- TODO - remove
    self.airFriction = config.airFriction or airFriction
    self.groundFriction = config.groundFriction or groundFriction
  end

  -- Dynamic variables

  self.velocity = gmt.vector2D.new(0, 0)
  self.onGround = false
end

function RigidBody:getIsTouchingGround()
  return self.onGround
end

function RigidBody:getCurrentVelocity()
  return self.velocity
end

function RigidBody:addVelocityX(dX)
  self.velocity.dx += dX
end

function RigidBody:setVelocityY(dY)
  self.velocity.dy = dY
end

function RigidBody:update()
  local sprite = self.sprite

  -- calculate new position by adding velocity to current position
  local newPos = gmt.vector2D.new(sprite.x, sprite.y) + (self.velocity * _G.delta_time)

  local _, _, sdkCollisions = sprite:moveWithCollisions(newPos:unpack())

  -- Reset variables

  self.onGround = false
  
  for _, c in pairs(sdkCollisions) do
    local tag = c.other:getTag()
    local _, normalY = c.normal:unpack()

    -- Detect if ground collision

    if normalY == -1 and PROPS.Ground[tag] then
      self.onGround = true
    end
  end

  -- incorporate gravity

  if self.onGround then
    -- Resets velocity, still applying gravity vector

    local dx, _ = self.velocity:unpack()
    self.velocity = gmt.vector2D.new(dx, self.gravity * _G.delta_time)

    -- Apply Ground Friction

    self.velocity:addVector(gmt.vector2D.new((-self.velocity:unpack() * self.groundFriction) * _G.delta_time, 0))
  else
    -- Adds gravity vector to current velocity

    self.velocity = self.velocity + (gmt.vector2D.new(0, 1) * _G.delta_time) * self.gravity

    -- Apply Air Friction

    self.velocity:addVector(gmt.vector2D.new((-self.velocity:unpack() * self.airFriction) * _G.delta_time, 0))
  end

  -- Call sprite's extra collision handling if available

  for _, c in pairs(sdkCollisions) do
    if sprite.handleCollision then
      sprite:handleCollision(c)
    end
  end
end
