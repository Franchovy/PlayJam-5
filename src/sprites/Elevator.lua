import "elevator/elevatorTrack"

local gfx <const> = playdate.graphics
local gmt <const> = playdate.geometry
local vector2D <const> = gmt.vector2D

local imageElevator <const> = gfx.image.new(assets.images.elevator)

local tileAdjustmentPx <const> = 4

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

function Elevator:setActivatingSprite(sprite)
  self.sprite = sprite
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

local function collisionsCheckForSprite(self)
  if not self.sprite then
    return
  end

  local destinationX, destinationY = self.sprite.x, self.sprite.y
  
  if self.fields.orientation == ORIENTATION.Horizontal then
    destinationX += self.movement
  else
    destinationY += self.movement
  end
  
  local _, _, collisions = self.sprite:checkCollisions(destinationX, destinationY)

  print(#collisions)

  return true
end

-- Public class Methods

--- Sets movement to be executed in the next update() call using vector.
--- *param* key - the player input key direction (KEYNAMES)
--- *returns* whether an activation occurred based on key press.
function Elevator:activate(key)
  -- Get distance remaining
  local movement = getMovementRemaining(self, key)
  
  -- Set movement update scalar
  self.movement = movement

  self.displacement += self.movement * _G.delta_time

  -- If close to start or end, adjust displacement & cancel movement
  if self.displacement - self.displacementStart < 1 or
    self.displacementEnd - self.displacement < 1 then
      self:displacementAdjustToTile()
      self.movement = 0
  end

  -- Return boolean - did activation call capture movement

  return movement ~= 0, movement
end

--- If elevator is within `tileAdjustmentPx` of tile, then adjusts
--- `self.displacement` to be on that tile exactly.
function Elevator:displacementAdjustToTile()

  local adjustmentDown = self.displacement % TILE_SIZE
  local adjustmentUp = TILE_SIZE - (self.displacement % TILE_SIZE)
  if adjustmentDown > 0 and adjustmentDown < tileAdjustmentPx then
    -- Adjust downwards
    self.displacement -= adjustmentDown
  elseif adjustmentUp > 0 and adjustmentUp < tileAdjustmentPx then
    -- Adjust upwards
    self.displacement += adjustmentUp
  end

end

function Elevator:updatePosition()

  -- Move to new position using displacement

  if self.fields.orientation == ORIENTATION.Horizontal then
    self:moveTo(self.initialPosition.x + self.displacement, self.initialPosition.y)
  else
    self:moveTo(self.initialPosition.x, self.initialPosition.y + self.displacement)
  end

  -- Update checkpoint state

  self.checkpointHandler:pushState({x = self.x, y = self.y, displacement = self.displacement})
end

function Elevator:update()
  Elevator.super.update(self)

  -- Skip displacement to the nearest tile 

  if self.movement ~= 0 then

    -- Check collisions

    local isCollisionCheckPassed = collisionsCheckForSprite(self)

    -- Set sprite position

    self:updatePosition()

  elseif self.fields.orientation == ORIENTATION.Vertical then
    -- If not active, adjust for pixel-perfect tile position

    self:displacementAdjustToTile()

    self:updatePosition()
  end

  -- Reset collisions if disabled

  if self.isCollisionsDisabledForFrame then
    self:setCollisionsEnabled(true)

    self.isCollisionsDisabledForFrame = false
  end

  -- Reset update variables
  
  self.movement = 0
  self.sprite = nil
end

function Elevator:handleCheckpointRevert(state)
  self.movement = 0

  self:moveTo(state.x, state.y)

  self.displacement = state.displacement
end