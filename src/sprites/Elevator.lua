local gfx <const> = playdate.graphics
local gmt <const> = playdate.geometry
local vector2D <const> = gmt.vector2D

local ORIENTATION <const> = {
  Horizontal = "Horizontal",
  Vertical = "Vertical"
}

local imageElevator <const> = gfx.image.new(assets.images.elevator)

-- Private Static methods

--- Categorize UP and RIGHT as positive direction and DOWN and LEFT as negative/"inverse" direction.
local function isInverseDirection(key)
  return key == KEYNAMES.Up or key == KEYNAMES.Left
end

class("Elevator").extends(gfx.sprite)

function Elevator:init(entity)
  Elevator.super.init(self, imageElevator)

  self:setTag(TAGS.Elevator)
  self:setCenter(0.5, 1)

  -- LDtk fields

  self.fields = table.deepcopy(entity.fields)

  -- Set Displacement initial, start and end scalars (1D) based on entity fields

  self.displacement = (self.fields.initialDistance or 0) * TILE_SIZE -- [Franch] We can make the initial displacement greater than 0.
  self.displacementStart = 0 -- Add extra pixel for smooth platforming
  self.displacementEnd = self.fields.distance * TILE_SIZE

  -- RigidBody config

  self.rigidBody = RigidBody(self, {gravity = 0})

  -- Elevator-specific fields

  self.speed = 3 -- [Franch] Constant, but could be modified on a per-elevator basis in the future.
  self.movement = vector2D.ZERO -- 2D update vector for movement. 
end

function Elevator:postInit()
  -- Checkpoint Handling setup

  self.checkpointHandler = CheckpointHandler(self, { x = self.x, y = self.y, displacement = self.displacement })
end

function Elevator:collisionResponse(_)
  return gfx.sprite.kCollisionTypeSlide
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
  
  -- Calculate movement as scalar value, invert speed if inverse direction

  return math.floor(math.min(displacementRemaining, self.speed) * (isInverseDirection and -1 or 1))
end

-- Public class Methods

--- Sets movement to be executed in the next update() call using vector.
--- *param* key - the player input key direction (KEYNAMES)
--- *returns* whether an activation occurred based on key press.
function Elevator:activate(key)
  local movement = 0

  if (key == KEYNAMES.Left or key == KEYNAMES.Right)
  and self.fields.orientation == ORIENTATION.Horizontal then
    -- Horizontal movement - get distance remaining
    movement = getMovementRemaining(self, key)

    -- Update movement update vector applying orientation
    self.movement = vector2D.new(movement, 0)
elseif (key == KEYNAMES.Down or key == KEYNAMES.Up)
  and self.fields.orientation == ORIENTATION.Vertical then
    -- Vertical movement - get distance remaining
    movement = getMovementRemaining(self, key)

    -- Update movement update vector applying orientation
    self.movement = vector2D.new(0, movement)
  end

  -- Return boolean - did activation call capture movement

  return movement ~= 0
end

function Elevator:update()
  Elevator.super.update(self)
  
  -- Don't call RigidBody update here, as that does collision work
  -- and we just want to call `moveTo` for the elevator

  -- self.rigidBody:update()

  -- Move elevator if update vector has been set

  if self.movement ~= vector2D.ZERO then

    local newPos = vector2D.new(self.x, self.y) + (self.movement * _G.delta_time)

    self:moveTo(newPos.dx, newPos.dy)
    
    -- Update displacement to match movement
    
    if self.fields.orientation == ORIENTATION.Horizontal then
      self.displacement += self.movement.x * _G.delta_time
    else
      self.displacement += self.movement.y * _G.delta_time
    end
    
    -- Update checkpoint state

    self.checkpointHandler:pushState({x = self.x, y = self.y, displacement = self.displacement})

    -- Reset movement vector
    
    self.movement = vector2D.ZERO
  end
end

function Elevator:handleCheckpointRevert(state)
  self.movement = vector2D.ZERO

  self:moveTo(state.x, state.y)

  self.displacement = state.displacement
end