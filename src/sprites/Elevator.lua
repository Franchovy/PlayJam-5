local gfx <const> = playdate.graphics
local gmt <const> = playdate.geometry
local timer <const> = playdate.timer
local vector2D <const> = gmt.vector2D

local ORIENTATION <const> = {
  Horizontal = "Horizontal",
  Vertical = "Vertical"
}

-- Private Static methods

--- Categorize UP and RIGHT as positive direction and DOWN and LEFT as negative/"inverse" direction.
local function isInverseDirection(key)
  return key == KEYNAMES.Up or key == KEYNAMES.Left
end

class("Elevator").extends(RigidBody)

local maxVelocity = 5
local speed = 1

function Elevator:init(entity)
  local imageElevator = gfx.imagetable.new("assets/images/elevator")
  Elevator.super.init(self, entity, imageElevator)

  self.fields = table.deepcopy(entity.fields)
  self:setTag(TAGS.Elevator)

  -- Set start and end position based on orientation & distance

  self.displacement = (self.fields.initialDistance or 0) * TILE_SIZE -- [Franch] We can make the initial displacement greater than 0.
  
  self.displacementStart = 0
  self.displacementEnd = self.fields.distance * TILE_SIZE

  -- AnimatedSprite config

  self:addState("n", 1, 1).asDefault()
  self:playAnimation()

  -- RigidBody config

  self.g_mult = 0
  self.inv_mass = 0
  self.restitution = 0.0

  -- Elevator-specific fields

  self.speed = 3 -- [Franch] Constant, but could be modified on a per-elevator basis in the future.
  self.movement = vector2D.ZERO
end

-- Private class methods

--- Get remaining movement based on direction and displacement
local function getMovementRemaining(self, key)
  -- Get inverted direction boolean
  local isInverseDirection = isInverseDirection(key)

  -- Remaining displacement - either towards displacementEnd or displacementStart if inverse direction
  local displacementRemaining = isInverseDirection 
    and self.displacement - self.displacementStart
    or self.displacementEnd - self.displacement
  
  -- Create 2D vector used in update() call for movement, invert speed if inverse direction

  local movement = math.min(displacementRemaining, self.speed) * (isInverseDirection and -1 or 1)

  return movement
end

-- Public class Methods

--- Sets movement to be executed in the next update() call using vector.
--- *param* key - the input Key direction
function Elevator:activate(key)
  local movement = 0

  if (key == KEYNAMES.Left or key == KEYNAMES.Right) 
  and self.fields.orientation == ORIENTATION.Horizontal then
    -- Horizontal movement - get distance remaining
    movement = getMovementRemaining(self, key)

    -- Set movement vector
    self.movement = vector2D.new(movement, 0)
elseif (key == KEYNAMES.Down or key == KEYNAMES.Up) 
  and self.fields.orientation == ORIENTATION.Vertical then
    -- Vertical movement - get distance remaining
    movement = getMovementRemaining(self, key)

    -- Set movement vector
    self.movement = vector2D.new(0, movement)
  end

  -- Update displacement

  self.displacement += movement

  -- Return boolean - did activation call capture movement

  return movement ~= 0
end

function Elevator:update()
  -- don't call SUPER update here, as that does collision work
  -- and we just want to call `moveTo` for the elevator
  -- Elevator.super.update(self)

  local newPos = vector2D.new(self.x, self.y) + (self.movement * _G.delta_time)

  self:moveTo(newPos.dx, newPos.dy)

  -- Reset movement vector
  
  self.movement = vector2D.ZERO
end