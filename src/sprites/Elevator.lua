import "elevator/elevatorTrack"

local gfx <const> = playdate.graphics
local gmt <const> = playdate.geometry
local vector2D <const> = gmt.vector2D

local imageElevator <const> = gfx.image.new(assets.images.elevator)

local tileAdjustmentPx <const> = 5

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

  self.rigidBody = RigidBody(self)

  -- Elevator-specific fields

  self.speed = 5 -- [Franch] Constant, but could be modified on a per-elevator basis in the future.
  self.movement = 0 -- Update scalar for movement. 

  -- Create elevator track

  self.spriteElevatorTrack = ElevatorTrack(self.fields.distance, entity.fields.orientation)
end

function Elevator:postInit()
  -- Checkpoint Handling setup

  self.checkpointHandler = CheckpointHandler(self, { x = self.x, y = self.y, displacement = self.displacement })

  -- Save initial position

  if self.fields.orientation == ORIENTATION.Horizontal then
    self.initialPosition = gmt.point.new(self.x - self.displacement, self.y)
    self.finalPosition = gmt.point.new(self.initialPosition.x + self.displacementEnd, self.y)
  else
    self.initialPosition = gmt.point.new(self.x, self.y - self.displacement)
    self.finalPosition = gmt.point.new(self.x, self.initialPosition.y + self.displacementEnd)
  end

  -- Positon elevator track

  self.spriteElevatorTrack:setInitialPosition(self.initialPosition)
  self.spriteElevatorTrack:add()
end

function Elevator:collisionResponse(_)
  return gfx.sprite.kCollisionTypeSlide
end

--- Used specifically for when jumping while moving up with elevator.
function Elevator:disableCollisionsForFrame()
  self:setCollisionsEnabled(false)

  self.isCollisionsDisabledForFrame = true
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

  return math.min(displacementRemaining, self.speed) * (isInverseDirection and -1 or 1)
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

  elseif (key == KEYNAMES.Down or key == KEYNAMES.Up)
  and self.fields.orientation == ORIENTATION.Vertical then
    -- Vertical movement - get distance remaining
    movement = getMovementRemaining(self, key)
  end
  
  -- Set movement update scalar
  self.movement = movement
  
  -- Return boolean - did activation call capture movement

  return movement ~= 0, movement
end

function Elevator:updatePosition()
  -- Move to new position using displacement

  if self.orientation == ORIENTATION.Horizontal then
    self:moveTo(self.initialPosition.x + self.displacement, self.initialPosition.y)
  else
    self:moveTo(self.initialPosition.x, self.initialPosition.y + self.displacement)
  end

  -- Update checkpoint state

  self.checkpointHandler:pushState({x = self.x, y = self.y, displacement = self.displacement})

end

function Elevator:update()
  Elevator.super.update(self)

  -- If Movement

  -- Update position / displacement

  -- If math.abs(Displacement % TILE_SIZE) < 1
  -- Skip displacement to the nearest tile 

  if self.movement ~= 0 then

    -- Update displacement

    self.displacement += self.movement * _G.delta_time

    -- Set sprite position

    self:updatePosition()

    -- Reset movement vector
    
    self.movement = 0
  else
    -- Adjust displacement to move to nearest tile

    local adjustmentDown = self.displacement % TILE_SIZE
    local adjustmentUp = TILE_SIZE - (self.displacement % TILE_SIZE)
    if adjustmentDown > 0 and adjustmentDown < tileAdjustmentPx then
      -- Adjust downwards
      self.displacement -= adjustmentDown
    elseif adjustmentUp > 0 and adjustmentUp < tileAdjustmentPx then
      -- Adjust upwards
      self.displacement += adjustmentUp
    end

    self:updatePosition()
  end

  -- Reset collisions if disabled

  if self.isCollisionsDisabledForFrame then
    self:setCollisionsEnabled(true)

    self.isCollisionsDisabledForFrame = false
  end
end

function Elevator:handleCheckpointRevert(state)
  self.movement = 0

  self:moveTo(state.x, state.y)

  self.displacement = state.displacement
end