local pd <const> = playdate
local sound <const> = pd.sound
local gmt <const> = pd.geometry
local gfx <const> = pd.graphics

local imagetablePlayer = gfx.imagetable.new(assets.imageTables.player)
local spJump = sound.sampleplayer.new("assets/sfx/Jump")
local spError = sound.sampleplayer.new("assets/sfx/Error")
local spDrill = sound.sampleplayer.new("assets/sfx/drill-start")
local spCheckpointRevert = sound.sampleplayer.new("assets/sfx/checkpoint-revert")
local spCollect = sound.sampleplayer.new("assets/sfx/Collect")

-- Level Bounds for camera movement (X,Y coords areas in global (world) coordinates)

local levelGX
local levelGY
local levelWidth
local levelHeight

-- Level offset for drawing levels smaller than screen size

local levelOffsetX
local levelOffsetY

-- Timer for handling cooldown on checkpoint revert

local timerCooldownCheckpoint

-- Boolean to keep overlapping with GUI state

local isOverlappingWithGUI = false

--

local ANIMATION_STATES = {
    Idle = 1,
    Moving = 2,
    Jumping = 3,
    Drilling = 4
}

KEYS = {
    [KEYNAMES.Up] = pd.kButtonUp,
    [KEYNAMES.Down] = pd.kButtonDown,
    [KEYNAMES.Left] = pd.kButtonLeft,
    [KEYNAMES.Right] = pd.kButtonRight,
    [KEYNAMES.A] = pd.kButtonA,
    [KEYNAMES.B] = pd.kButtonB
}

local groundAcceleration <const> = 7
local airAcceleration <const> = 1.5
local jumpSpeed <const> = 27
local jumpHoldTimeInTicks <const> = 4

-- TODO: [Franch]
-- Set timer to pause movement when doing checkpoint resets (0.5s probably)
-- Abilities (blueprints) should come from a single source, read from panel (or game)

-- Setup

class("Player").extends(AnimatedSprite)

-- Static Reference

local _instance

function Player.getInstance() return _instance end

function Player:init(entity)
    _instance = self

    Player.super.init(self, imagetablePlayer)

    -- AnimatedSprite states

    function pauseAnimation()
        self:pauseAnimation()
    end

    self:addState(ANIMATION_STATES.Idle, 1, 4, { tickStep = 3 }).asDefault()
    self:addState(ANIMATION_STATES.Jumping, 5, 8, { tickStep = 1, onLoopFinishedEvent = pauseAnimation })
    self:addState(ANIMATION_STATES.Moving, 9, 12, { tickStep = 2 })
    self:addState(ANIMATION_STATES.Drilling, 12, 16, { tickStep = 2 })
    self:playAnimation()

    self:setTag(TAGS.Player)

    self.isDroppingItem = false
    self.isActivatingDrillableBlock = false
    self.isActivatingElevator = false

    -- Setup keys array and starting keys

    self.blueprints = {}

    local startingKeys = entity.fields.blueprints
    for _, key in ipairs(startingKeys) do
        table.insert(self.blueprints, key)
    end

    Manager.emitEvent(EVENTS.UpdateBlueprints)

    -- RigidBody config

    local rigidBodyConfig = {
        groundFriction = 2,
        airFriction = 2,
        gravity = 5
    }

    self.rigidBody = RigidBody(self, rigidBodyConfig)

    -- Add Checkpoint handling

    self.checkpointHandler = CheckpointHandler(self)

    self.latestCheckpointPosition = gmt.point.new(self.x, self.y)
end

function Player:handleCheckpointRevert(state)
    self:moveTo(state.x, state.y)

    self.latestCheckpointPosition.x = state.x
    self.latestCheckpointPosition.y = state.y
    self.blueprints = state.blueprints

    Manager.emitEvent(EVENTS.UpdateBlueprints)
end

-- Enter Level

function Player:enterLevel(direction, levelBounds)
    local levelGXPrevious = levelGX
    local levelGYPrevious = levelGY
    local levelWidthPrevious = levelWidth
    local levelHeightPrevious = levelHeight

    -- Set persisted variables

    levelGX = levelBounds.x
    levelGY = levelBounds.y
    levelWidth = levelBounds.width
    levelHeight = levelBounds.height

    -- Set level draw offset

    levelOffsetX = levelWidth < 400 and (400 - levelWidth) / 2 or 0
    levelOffsetY = levelHeight < 240 and (240 - levelBounds.height) / 2 or 0

    -- Position player based on direction of entry

    if direction == DIRECTION.RIGHT then
        local x = (levelGXPrevious + levelWidthPrevious) - levelGX + 15
        local y = self.y + (levelGYPrevious - levelGY)

        self:moveTo(x, y)
    elseif direction == DIRECTION.LEFT then
        local x = levelWidth - 15
        local y = self.y + (levelGYPrevious - levelGY)

        self:moveTo(x, y)
    elseif direction == DIRECTION.BOTTOM then
        local x = self.x - (levelGX - levelGXPrevious)
        local y = (levelGYPrevious + levelHeightPrevious) - levelGY + 15

        self:moveTo(x, y)
    elseif direction == DIRECTION.TOP then
        local x = self.x + (levelGXPrevious - levelGX)
        local y = levelHeight + 15

        self:moveTo(x, y)
    end
end

function Player:setBlueprints(blueprints)
    self.blueprints = blueprints
end

-- Collision Response

function Player:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Wall or
        tag == TAGS.ConveyorBelt or
        tag == TAGS.Box or
        tag == TAGS.DrillableBlock or
        tag == TAGS.Elevator then
        return gfx.sprite.kCollisionTypeSlide
    else
        return gfx.sprite.kCollisionTypeOverlap
    end
end

-- Update Method

local jumpTimeLeftInTicks = jumpHoldTimeInTicks
local activeDrillableBlock
local activeDialog

function Player:handleCollision(collisionData)
    local other = collisionData.other
    local tag = other:getTag()

    -- If Drilling
    if tag == TAGS.DrillableBlock and self:isMovingDown() and collisionData.normal.y == -1  then
        -- Play drilling sound
        if not spDrill:isPlaying() then
            spDrill:play(1)
        end

        self.isActivatingDrillableBlock = other
    elseif self.isActivatingDrillableBlock then
        self.isActivatingDrillableBlock = nil
    end

    if tag == TAGS.Elevator then
        if collisionData.normal.y == -1 then
            local key
            if self:isMovingDown() then
                key = KEYNAMES.Down
            elseif self:isMovingUp() then
                key = KEYNAMES.Up
            elseif self:isMovingLeft() then
                key = KEYNAMES.Left
            elseif self:isMovingRight() then
                key = KEYNAMES.Right
            end

            if key then
                -- Elevator checks if it makes sense to activate
                local activationDistance = other:activate(self, key)

                if activationDistance and math.abs(activationDistance) ~= 0 then
                    -- If so, mark as activating elevator
                    self.isActivatingElevator = other
                end
            end
        end
    end

    if tag == TAGS.Ability then
        -- [FRANCH] This condition is useful in case there is more than one blueprint being picked up. However
        -- we should be handling the multiple blueprints as a single checkpoint.
        -- But it's also useful for debugging.

        if not timerCooldownCheckpoint then
            self:pickUpBlueprint(other)
        end
    end

    if tag == TAGS.Dialog then
        activeDialog = other
    end
end

function Player:update()
    -- Sprite update

    Player.super.update(self)

    -- Checkpoint Handling

    self:handleCheckpoint()

    -- Skip movement handling if timer cooldown is active
    if not timerCooldownCheckpoint then

        -- Movement handling (update velocity X and Y)

        -- Velocity X

        if self.isActivatingElevator and self.isActivatingElevator:wasActivationSuccessful() then
            -- Skip horizontal movement
        elseif not self.isActivatingDrillableBlock then
            self:handleHorizontalMovement()
        end

        -- Velocity Y

        if self.rigidBody:getIsTouchingGround() then
            local isJumpStart = self:handleJumpStart()

            if isJumpStart and self.isActivatingElevator then
                -- Disable collisions with elevator for this frame to avoid
                -- jump / moving elevator up collisions glitch.
                self.isActivatingElevator:disableCollisionsForFrame()
            end
        else
            self:handleJump()
        end

        -- Drilling

        if self.isActivatingDrillableBlock then
            -- Activate block drilling

            self.isActivatingDrillableBlock:activate()

            -- Move player to Center on top of the drilled block

            local centerBlockX = self.isActivatingDrillableBlock.x + self.isActivatingDrillableBlock.width / 2

            self:moveTo(
                centerBlockX - self.width / 2,
                self.isActivatingDrillableBlock.y - self.height
            )
        end

        -- Reset update variables before update

        self.isActivatingElevator = false
        self.isActivatingDrillableBlock = false

        -- RigidBody update

        self.rigidBody:update()
    end

    -- Update dialog

    if activeDialog then
        activeDialog:activate()

        -- Consume variable
        activeDialog = nil
    end

    -- Update state for checkpoint

    local state = self.checkpointHandler:getStateCurrent()
    if state then
        -- Update the state directly. No need to push new

        state.x = self.x
        state.y = self.y
        state.blueprints = self.blueprints
    else
        if self.x ~= self.latestCheckpointPosition.x or self.y ~= self.latestCheckpointPosition.y then
            self.latestCheckpointPosition.x = self.x
            self.latestCheckpointPosition.y = self.y
            self.checkpointHandler:pushState({
                x = self.latestCheckpointPosition.x,
                y = self.latestCheckpointPosition.y,
                blueprints = table.deepcopy(self.blueprints)
            })
        end
    end

    -- Animation Handling

    self:updateAnimationState()

    -- Camera Movement

    local playerX, playerY = self.x, self.y
    local idealX, idealY = playerX - 200, playerY - 100

    -- Positon camera within level bounds

    local cameraOffsetX = math.max(math.min(idealX, levelWidth - 400), 0)
    local cameraOffsetY = math.max(math.min(idealY, levelHeight - 240), 0)

    gfx.setDrawOffset(-cameraOffsetX + levelOffsetX, -cameraOffsetY + levelOffsetY)

    -- Check if player is in top-left of level (overlap with GUI)

    local isOverlappingWithGUIPrevious = isOverlappingWithGUI

    if playerX < 100 and playerY < 40 then
        isOverlappingWithGUI = true
    else
        isOverlappingWithGUI = false
    end

    if isOverlappingWithGUI ~= isOverlappingWithGUIPrevious then
        -- Signal to hide or show GUI based on overlap
        Manager.emitEvent(EVENTS.HideOrShowGUI, isOverlappingWithGUI)
    end

    -- Check if player has moved into another level

    local direction

    if playerX > levelWidth then
        direction = DIRECTION.RIGHT
    elseif playerX < 0 then
        direction = DIRECTION.LEFT
    end

    if playerY > levelHeight then
        direction = DIRECTION.BOTTOM
    elseif playerY < 0 then -- Add a margin to not trigger level change so easily.
        direction = DIRECTION.TOP
    end

    if direction then
        Manager.emitEvent(EVENTS.LevelComplete,
            { direction = direction, coordinates = { x = playerX + levelGX, y = playerY + levelGY } })
    end
end

function Player:revertCheckpoint()
    -- SFX

    spCheckpointRevert:play(1)

    -- Emit the event for the rest of the scene

    Manager.emitEvent(EVENTS.CheckpointRevert)

    -- Cooldown timer for checkpoint revert

    timerCooldownCheckpoint = playdate.timer.new(500)
    timerCooldownCheckpoint.timerEndedCallback = function(timer)
        timer:remove()

        -- Since there can be multiple checkpoint-reverts in sequence, we want to
        -- ensure we're not removing a timer that's not this one.
        if timerCooldownCheckpoint == timer then
            timerCooldownCheckpoint = nil
        end
    end
end

function Player:pickUpBlueprint(blueprint)
    -- Emit pickup event for abilty panel

    blueprint:updateStatePickedUp()
    spCollect:play(1)

    -- Update blueprints list

    -- Keeping blueprints in separate table for checkpoint state purpose
    local blueprintsNew = table.deepcopy(self.blueprints)

    if #blueprintsNew == 3 then
        table.remove(blueprintsNew, 1)
    end

    table.insert(blueprintsNew, blueprint.abilityName)

    self.blueprints = blueprintsNew

    self.checkpointHandler:pushState({
        x = self.x,
        y = self.y,
        blueprints = self.blueprints
    })

    Manager.emitEvent(EVENTS.UpdateBlueprints)

    -- Update checkpoints

    Manager.emitEvent(EVENTS.CheckpointIncrement)
end

function Player:enterLevel(direction, levelBounds)
    local levelGXPrevious = levelGX
    local levelGYPrevious = levelGY
    local levelWidthPrevious = levelWidth
    local levelHeightPrevious = levelHeight

    -- Set persisted variables

    levelGX = levelBounds.x
    levelGY = levelBounds.y
    levelWidth = levelBounds.width
    levelHeight = levelBounds.height

    -- Set level draw offset

    levelOffsetX = levelWidth < 400 and (400 - levelWidth) / 2 or 0
    levelOffsetY = levelHeight < 240 and (240 - levelBounds.height) / 2 or 0

    -- Position player based on direction of entry

    if direction == DIRECTION.RIGHT then
        local x = (levelGXPrevious + levelWidthPrevious) - levelGX + 15
        local y = self.y + (levelGYPrevious - levelGY)

        self:moveTo(x, y)
    elseif direction == DIRECTION.LEFT then
        local x = levelWidth - 15
        local y = self.y + (levelGYPrevious - levelGY)

        self:moveTo(x, y)
    elseif direction == DIRECTION.BOTTOM then
        local x = self.x - (levelGX - levelGXPrevious)
        local y = (levelGYPrevious + levelHeightPrevious) - levelGY + 15

        self:moveTo(x, y)
    elseif direction == DIRECTION.TOP then
        local x = self.x + (levelGXPrevious - levelGX)
        local y = levelHeight - 15

        self:moveTo(x, y)
    end

    -- Push level position
    self.checkpointHandler:pushState({
        x = self.x,
        y = self.y,
        blueprints = table.deepcopy(self.blueprints)
    })

    -- Set a cooldown timer to prevent key presses on enter

    timerCooldownCheckpoint = playdate.timer.new(50)
    timerCooldownCheckpoint.timerEndedCallback = function(timer)
        timer:remove()

        -- Since there can be multiple checkpoint-reverts in sequence, we want to
        -- ensure we're not removing a timer that's not this one.
        if timerCooldownCheckpoint == timer then
            timerCooldownCheckpoint = nil
        end
    end
end

-- Animation Handling

local flip

function Player:updateAnimationState()
    local animationState
    local velocity = self.rigidBody:getCurrentVelocity()
    local isMoving = math.floor(math.abs(velocity.dx)) > 0

    if self.rigidBody:getIsTouchingGround() then
        if self.isActivatingDrillableBlock then
            animationState = ANIMATION_STATES.Drilling
        elseif isMoving and not self.isActivatingElevator then
            animationState = ANIMATION_STATES.Moving
        else
            animationState = ANIMATION_STATES.Idle
        end
    else
        animationState = ANIMATION_STATES.Jumping
    end

    -- Handle direction (flip)

    if velocity.dx < 0 then
        self.states[animationState].flip = 1
    elseif velocity.dx > 0 then
        self.states[animationState].flip = 0
    end

    self:changeState(animationState)
end

-- Input Handlers --

function Player:handleCheckpoint()
    if self:justPressedCheckpoint() then
        self:revertCheckpoint()
    end
end

-- Jump

function Player:handleJumpStart()
    if pd.buttonJustPressed(KEYNAMES.A) and self:isJumping() then
        spJump:play(1)

        self.rigidBody:setVelocityY(-jumpSpeed)

        jumpTimeLeftInTicks -= 1

        return true
    end

    return false
end

function Player:handleJump()
    if self:isJumping() and jumpTimeLeftInTicks > 0 then
        -- Hold Jump

        self.rigidBody:setVelocityY(-jumpSpeed)

        jumpTimeLeftInTicks -= 1
    elseif pd.buttonJustReleased(KEYNAMES.A) or jumpTimeLeftInTicks > 0 then
        -- Released Jump

        jumpTimeLeftInTicks = 0
    end
end

-- Directional

function Player:handleHorizontalMovement()
    local acceleration = self.rigidBody:getIsTouchingGround() and groundAcceleration or airAcceleration
    if self:isMovingLeft() then
        self.rigidBody:addVelocityX(-acceleration)
    elseif self:isMovingRight() then
        self.rigidBody:addVelocityX(acceleration)
    end
end

-- Input Handlers

function Player:justPressedCheckpoint()
    -- No key gating on checkpoint
    return pd.buttonJustPressed(KEYNAMES.B)
end

function Player:isJumping()
    return self:isKeyPressedGated(KEYNAMES.A)
end

function Player:isMovingRight()
    return self:isKeyPressedGated(KEYNAMES.Right)
end

function Player:isMovingLeft()
    return self:isKeyPressedGated(KEYNAMES.Left)
end

function Player:isMovingUp()
    return self:isKeyPressedGated(KEYNAMES.Up)
end

function Player:isMovingDown()
    return self:isKeyPressedGated(KEYNAMES.Down)
end

-- Generic gated input handler

local shouldSkipKeyGate = false
function Player:isKeyPressedGated(key)
    --debug
    if shouldSkipKeyGate then
        return pd.buttonIsPressed(key)
    end

    for _, abilityName in ipairs(self.blueprints) do
        if abilityName == key then
            return pd.buttonIsPressed(abilityName)
        end
    end
    if pd.buttonJustPressed(key) then
        spError:play(1)
    end
    return false
end
