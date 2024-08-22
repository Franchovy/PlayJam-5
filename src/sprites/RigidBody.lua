local pd <const> = playdate
local gmt <const> = pd.geometry
local gfx <const> = pd.graphics

class("RigidBody").extends()

local gravity <const> = 1
local airFriction <const> = .14
local groundFriction <const> = .3
local maxFallSpeed <const> = 13 -- TODO - remove
local maxConveyorSpeed <const> = 6 -- TODO - remove

function RigidBody:init(sprite, config)
  self.sprite = sprite

  -- Config

  if config then
    self.gravity = config.gravity or gravity -- TODO - remove
    self.airFriction = config.airFriction or airFriction
    self.groundFriction = config.groundFriction or groundFriction
    self.maxFallSpeed = config.maxFallSpeed or maxFallSpeed-- TODO - remove
    self.maxConveyorSpeed = config.maxConveyorSpeed or maxConveyorSpeed -- TODO - remove
  end

  -- Dynamic variables

  self.velocity = gmt.vector2D.new(0, 0)
  self.onParent = false
  self.shouldSkipPhysicsHandling = false
  self.shouldExitParent = false
  self.onGround = false
  self.parent = nil
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

function RigidBody:setExitParent()
  self.shouldExitParent = true
end

--- Skips physics handling for one frame.
function RigidBody:skipPhysicsHandling()
  self.shouldSkipPhysicsHandling = true
end

function RigidBody:update()
  local sprite = self.sprite

  if self.shouldSkipPhysicsHandling then
    self.shouldSkipPhysicsHandling = false

    -- Skip physics handling
    return
  end

  local shouldExitParent = false
  if self.shouldExitParent then
    -- Consume shouldExitParent if set
    
    self.shouldExitParent = false

    shouldExitParent = true
  end

  -- calculate new position by adding velocity to current position
  local newPos
  if self.onParent and self.parent and not shouldExitParent then
    newPos = gmt.vector2D.new(self.parent.x, self.parent.y - self.parent.height/2) + (self.velocity * _G.delta_time)
  else
    newPos = gmt.vector2D.new(sprite.x, sprite.y) + (self.velocity * _G.delta_time)
  end

  local newX, newY = newPos:unpack()
  local currentVX, _ = self.velocity:unpack()

  local _, _, sdkCollisions = sprite:moveWithCollisions(newX, newY)

  local parentFound = false
  local groundFound = false

  for _, c in pairs(sdkCollisions) do
    local other = c.other
    local tag = other:getTag()
    local normal = c.normal
    local _, normalY = normal:unpack()

    -- Detect if ground collision

    if normalY == -1 and PROPS.Ground[tag] and not groundFound then
      groundFound = true
    end

    -- Detect if ground collision creates parent

    -- TODO - simplify conditional
    if groundFound and PROPS.Parent[tag] and not parentFound and not shouldExitParent then
      parentFound = true
      self.parent = other
    end

    -- Conveyor Belt movement handling

    -- TODO - see if this can be extracted to the collision belt itself
    if tag == TAGS.ConveyorBelt and normalY == -1 and math.abs(currentVX) < self.maxConveyorSpeed then
      local conveyorSpeed = other:getAppliedSpeed()
      self.velocity = self.velocity + (gmt.vector2D.new(conveyorSpeed, 0) * _G.delta_time)
    end

    -- Call sprite's extra collision handling if available

    if sprite.handleCollision then
      sprite:handleCollision(c)
    end
  end

  self.onGround = groundFound
  self.onParent = parentFound

  -- incorporate gravity

  if not groundFound then
    -- Adds gravity vector to current velocity

    self.velocity = self.velocity + (gmt.vector2D.new(0, 1) * _G.delta_time) * self.gravity
  elseif groundFound then
    -- Resets velocity (still applying gravity)

    local dx, _ = self.velocity:unpack()
    self.velocity = gmt.vector2D.new(dx, self.gravity * _G.delta_time)
  end

  -- incorporate any in-air drag
  if not groundFound and currentVX ~= 0 then
    self.velocity:addVector(gmt.vector2D.new((-currentVX * self.airFriction) * _G.delta_time, 0))
  end

  -- incorporate any ground friction
  if groundFound and currentVX ~= 0 then
    self.velocity:addVector(gmt.vector2D.new((-currentVX * self.groundFriction) * _G.delta_time, 0))
  end
end
