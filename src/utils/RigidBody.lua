local pd <const> = playdate
local gmt <const> = pd.geometry
local gfx <const> = pd.graphics

class("RigidBody").extends()

local gravity <const> = 1
local airFriction <const> = .14
local groundFriction <const> = .3

local vGravity <const> = gmt.vector2D.new(0, gravity)

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

-- WIP: New structure
-- RigidBody.update() global call before gfx.sprite.update()
-- RigidBody calls applyForces for sprites based on latest state and keys pressed
-- Parent structure stored in a map, parents calculated before children
-- Collisions and parent structure accessible from RigidBody interface
-- Each sprite:update uses latest collisions to update their own state

-- RigidBody calculate forces
-- Collision sim
-- Pushing sprites vs. non-pushing sprites (mass?)
-- Sprites 


function RigidBody:update()
  -- Calculate Forces

  local vForces = gmt.vector2D.new(0, 0)

  if self.sprite.applyForces then
    self.sprite:applyForces(vForces)
  end

  -- Update Velocity and Position
  
  self.velocity.x = self.velocity.x + vForces.x * _G.delta_time
  self.velocity.y = self.velocity.y + vForces.y * _G.delta_time

  local idealX = self.sprite.x + self.velocity.x * _G.delta_time
  local idealY = self.sprite.y + self.velocity.y * _G.delta_time
  
  -- Use moveWithCollisions to move sprite

  local _, _, collisions = self.sprite:moveWithCollisions(idealX, idealY)

  -- Detect Collisions

  -- Collided with Ground?

  local onGround = false
  local touchedWall = false
  local touchedCeiling = false

  for _, c in pairs(collisions) do
    local other = c.other
    local tag = other:getTag()
    local normal = c.normal

    -- Detect if ground collision

    if normal.y == -1 and PROPS.Ground[tag] then
      onGround = true
    end

    -- Detect ceiling collision

    if normal.y == 1 then
      touchedCeiling = true
    end

    -- Detect if wall collision

    if normal.x ~= 0 then
      touchedWall = true
    end
  end

  if onGround then
    -- Reset Y Velocity

    self.velocity.y = 0

    -- TODO: WIP this is for in-sprite ground handling
    self.onGround = true
  else
    self.onGround = false
  end

  if touchedWall then
    self.velocity.x = 0
  end

  if touchedCeiling then
    self.velocity.y = 0
  end

  -- Solve Constraints

end

function RigidBody:updateOld()
  local sprite = self.sprite

  -- calculate new position by adding velocity to current position
  local newPos = gmt.vector2D.new(sprite.x, sprite.y) + (self.velocity * _G.delta_time)

  local _, _, sdkCollisions = sprite:moveWithCollisions(newPos:unpack())

  -- Reset variables

  self.onGround = false
  self.shouldParent = false
  
  for _, c in pairs(sdkCollisions) do
    local tag = c.other:getTag()
    local _, normalY = c.normal:unpack()

    -- Detect if ground collision

    if normalY == -1 and PROPS.Ground[tag] then
      self.onGround = true
    end

    -- Detect if parent collision

    if self.sprite.handleShouldParent and self.sprite:handleShouldParent(c) then
      assert(not self.shouldParent, "Two parents detected in the same frame! The system is not yet capable of handling this.")

      self.shouldParent = c.other
    end
  end

  -- incorporate gravity

  if self.shouldParent and self.sprite.handleGetParentVelocity then
    self.velocity = self.sprite:handleGetParentVelocity(self.shouldParent)

  elseif self.onGround then
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
