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

--- If elevator is within `tileAdjustmentPx` of tile, then adjusts
--- `self.displacement` to be on that tile exactly.
local function displacementAdjustToTile(self)
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


-- Public class Methods

--- Sets movement to be executed in the next update() call using vector.
--- *param* key - the player input key direction (KEYNAMES)
--- *returns* whether an activation occurred based on key press.
function Elevator:activate(sprite, key)
  -- Gets applied movement using key, self.speed and self.orientation
  local activationMovement = getActivationMovement(self, key)

  if activationMovement ~= 0 then
    -- Clamp movement to distance remaining
    local movement = getMovementRemaining(self, activationMovement)
      
    -- Update displacement
    self.displacement += movement * _G.delta_time

    -- If close to start or end, adjust displacement & cancel movement
    if self.displacement - self.displacementStart < 1 or
      self.displacementEnd - self.displacement < 1 then
        displacementAdjustToTile(self)
        movement = 0
    end

    if movement ~= 0 then
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

    -- Update position

    self:updatePosition()

    -- Update child position

    local centerX = self.x + self.width / 2

    local offsetY = 0
    if self.movement < 0 and self.fields.orientation == ORIENTATION.Vertical then
      -- For moving down, move player slightly into elevator for better collision activation
      offsetY = 0
    end

    self.spriteChild:moveTo(
      centerX - self.spriteChild.width / 2, 
      self.y - self.spriteChild.height - offsetY
    )

  elseif self.fields.orientation == ORIENTATION.Vertical then
    -- If not active, adjust for pixel-perfect tile position

    displacementAdjustToTile(self)

    self:updatePosition()
  end

  -- Reset collisions if disabled

  if self.isCollisionsDisabledForFrame then
    self:setCollisionsEnabled(true)

    self.isCollisionsDisabledForFrame = false
  end

  --[[
  -- Move player to the center of the platform
  local centerElevatorX = other.x + other.width / 2
  local offsetX, offsetY = 0, 0

  if key == KEYNAMES.Down and activationDistance > 1 then
      -- For moving down, move player slightly into elevator for better collision activation
      offsetY = activationDistance
  end
  
  self:moveTo(
      centerElevatorX - self.width / 2 + offsetX, 
      other.y - self.height + offsetY
  )

  -- Set the elevator variable for self, and sprite variable for other
  self.isActivatingElevator = other
  ]]

  -- Reset update variables
  
  self.movement = 0
  self.sprite = nil
end

function Elevator:handleCheckpointRevert(state)
  self.movement = 0

  self:moveTo(state.x, state.y)

  self.displacement = state.displacement
end