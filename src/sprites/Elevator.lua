import "elevator/elevatorTrack"

local gfx <const> = playdate.graphics
local gmt <const> = playdate.geometry
local vector2D <const> = gmt.vector2D

local imageElevator <const> = gfx.image.new(assets.images.elevator)

local tileAdjustmentPx <const> = 4

-- Private Static methods

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

local function getActivationMovement(self, key)
  if self.fields.orientation == ORIENTATION.Horizontal then
    -- Horizontal orientation, return positive if Right, negative if Left

    if key == KEYNAMES.Right then
      return self.speed
    elseif key == KEYNAMES.Left then
      return -self.speed
    end
  else
    -- Vertical orientation, return positive if Down, negative if Up

    if key == KEYNAMES.Down then
      return self.speed
    elseif key == KEYNAMES.Up then
      return -self.speed
    end
  end

  -- If key is not a correct activation key, return 0

  return 0
end

--- Get remaining movement based on direction and displacement
local function getMovementRemaining(self, movement)
  if movement < 0 then
    return math.max(self.displacementStart - self.displacement, movement)
  elseif movement > 0 then
    return math.min(self.displacementEnd - self.displacement, movement)
  else
    return 0
  end
end

local function checkIfCollides(self, idealX, idealY)
  -- Check if elevator collides

  local actualX, actualY, collisions = self:checkCollisions(idealX, idealY)
  local isCollisionCheckPassed = true

  for _, collision in pairs(collisions) do
    if collision.other == self.spriteChild then
      goto continue
    end

    -- Block collision
    isCollisionCheckPassed = false

    ::continue::
  end

  -- Return if collision check failed

  if not isCollisionCheckPassed then
    return false, actualX, actualY
  end

  -- Check if child sprite collides

  assert(self.spriteChild, "Expected to have a child sprite in update loop for elevator")
  
  -- if either collide with something else than each other, block movement.

  local destinationX, destinationY
  
  if self.fields.orientation == ORIENTATION.Horizontal then
    destinationX = self.spriteChild.x + self.movement
    destinationY = self.spriteChild.y
  else
    destinationX = self.spriteChild.x
    destinationY = self.spriteChild.y + self.movement
  end
  
  --[[
  local spriteActualX, spriteActualY, collisions = self.spriteChild:checkCollisions(destinationX, destinationY)

  for _, collision in pairs(collisions) do

  end
    
  end

  print(#collisions)
  ]]

  return true
end

--- If elevator is within `tileAdjustmentPx` of tile, then adjusts
--- `self.displacement` to be on that tile exactly.
local function displacementAdjustToTile(self)

  -- Get adjustment from tiles both above and below.

  local adjustmentDown = self.displacement % TILE_SIZE
  local adjustmentUp = TILE_SIZE - (self.displacement % TILE_SIZE)

  if adjustmentDown > 0 and adjustmentDown < tileAdjustmentPx then
    -- Adjust downwards
    self.displacement -= adjustmentDown
  elseif adjustmentUp > 0 and adjustmentUp < tileAdjustmentPx then
    -- Adjust upwards
    self.displacement += adjustmentUp
  else
    -- If no adjustment made, return false
    return false
  end
  
  -- If adjustment was made, return true
  return true
end


-- Public class Methods

--- Sets movement to be executed in the next update() call using vector.
--- *param* key - the player input key direction (KEYNAMES)
--- *returns* whether an activation occurred based on key press.
function Elevator:activate(sprite, key)
  -- Gets applied movement using key, self.speed and self.orientation
  local activationMovement = getActivationMovement(self, key)

  if activationMovement ~= 0 then
    -- Clamp movement to distance remaining
    local movementRemaining = getMovementRemaining(self, activationMovement)
    
    -- If close to start or end, no activation, but we keep the remaining movement.

    if movementRemaining == 0 then
      
    elseif math.abs(movementRemaining) < self.speed then
      self.movement = movementRemaining

      return false
    end

    if movementRemaining ~= 0 then
    
      -- If activated, add child sprite for collision check
      if movement then
        self.spriteChild = sprite
      end

      -- Set movement update scalar
      self.movement = movement
            
      -- Return true if activated
      return true
    end
  end
  
  return false
end

function getPositionFromDisplacement(self)
  if self.fields.orientation == ORIENTATION.Horizontal then
    return self.initialPosition.x + self.displacement, self.initialPosition.y
  else
    return self.initialPosition.x, self.initialPosition.y + self.displacement
  end
end

function Elevator:update()
  Elevator.super.update(self)

  -- Get if elevator has been activated
  local isDisplacementChanged = self.movement ~= 0
  
  if not isDisplacementChanged and self.fields.orientation == ORIENTATION.Vertical then
    -- If not active, adjust for pixel-perfect tile position

    isDisplacementChanged = displacementAdjustToTile(self)
  end

  -- Skip displacement to the nearest tile 

  if isDisplacementChanged then  

    -- Get new position using displacement

    local x, y = getPositionFromDisplacement(self)

    -- Check collisions

    local isCollisionCheckPassed = checkIfCollides(self, x, y)

    if not isCollisionCheckPassed then
      
    end

    -- Update child position

    local centerX = self.x + self.width / 2

    local offsetY = 0
    if self.movement > 0 and self.fields.orientation == ORIENTATION.Vertical then
      -- For moving down, move player slightly into elevator for better collision activation
      offsetY = 2
    end

    self.spriteChild:moveTo(
      centerX - self.spriteChild.width / 2, 
      self.y - self.spriteChild.height + offsetY
    )

    -- Move to new position using displacement

    self:moveTo(x, y)

    -- Update checkpoint state

    self.checkpointHandler:pushState({x = self.x, y = self.y, displacement = self.displacement})
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