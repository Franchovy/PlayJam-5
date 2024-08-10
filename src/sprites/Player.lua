local pd <const> = playdate
local sound <const> = pd.sound
local gmt <const> = pd.geometry
local gfx <const> = pd.graphics

local spJump = sound.sampleplayer.new("assets/sfx/Jump")
local spError = sound.sampleplayer.new("assets/sfx/Error")
local spDrillStart = sound.sampleplayer.new("assets/sfx/drill-start")
local spDrillLoop = sound.sampleplayer.new("assets/sfx/drill-loop")
local spDrillEnd = sound.sampleplayer.new("assets/sfx/drill-end")
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

local maxSpeed <const> = 4.5
local groundAcceleration <const> = 10
local jumpSpeed <const> = 17.5
local jumpHoldTimeInTicks <const> = 4

-- TODO: [Franch]
-- Set timer to pause movement when doing checkpoint resets (0.5s probably)
-- Abilities (blueprints) should come from a single source, read from panel (or game)

-- Setup

class("Player").extends(RigidBody)

-- Static Reference

local _instance

function Player.getInstance() return _instance end

function Player:init(entity)
    _instance = self

    local playerImageTable = gfx.imagetable.new("assets/images/boseki-table-32-32")
    Player.super.init(self, entity, playerImageTable)

    -- RigidBody overrides/config
    self.ground_friction = 2
    self.air_friction = 2
    self.g_mult = 5

    -- AnimatedSprite states
    self:addState(ANIMATION_STATES.Idle, 1, 4, { tickStep = 2 }).asDefault()
    self:addState(ANIMATION_STATES.Moving, 5, 6, { tickStep = 2 })
    self:addState(ANIMATION_STATES.Jumping, 7, 11, { tickStep = 2 })
    self:addState(ANIMATION_STATES.Drilling, 12, 15, { tickStep = 2 })
    self:playAnimation()

    self:setTag(TAGS.Player)

    self.isDroppingItem = false
    self.isDrilling = false

    -- Setup keys array and starting keys
    self.blueprints = {}
    local startingKeys = entity.fields.blueprints
    for _, key in ipairs(startingKeys) do
        table.insert(self.blueprints, key)
    end

    Manager.emitEvent(EVENTS.UpdateBlueprints)

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
local drillableBlockCurrentlyDrilling

function Player:handleCollisionExtra(collisionData)
    local other = collisionData.other
    local tag = other:getTag()

    if self.onGround and
       self.isDrilling and
       other:getTag() == TAGS.DrillableBlock then

        drillableBlockCurrentlyDrilling = other

        drillableBlockCurrentlyDrilling:activate()
    elseif tag == TAGS.Ability then
        -- [FRANCH] This condition is useful in case there is more than one blueprint being picked up. However
        -- we should be handling the multiple blueprints as a single checkpoint.
        -- But it's also useful for debugging.

        if not timerCooldownCheckpoint then
            self:pickUpBlueprint(other)
        end
    end
end

function Player:update()
    Player.super.update(self)
    -- Checkpoint Handling

    self:handleCheckpoint()

    -- Crank

    local _, acceleratedChange = pd.getCrankChange()
    if acceleratedChange > 75 and not self.isDroppingItem then
        self:dropLastItem()
    end

    -- Drilling

    if self:isMovingDown() then
        if self.isDrilling == false then
            spDrillStart:play(1)
            spDrillStart:setFinishCallback(function()
                if self.isDrilling then
                    -- Play loop
                    spDrillLoop:play(0)
                end
            end)
        end

        self.isDrilling = true
    else
        if self.isDrilling then
            -- spDrillStart:stop() -- Until we have better samples, better to cover up the sfx gaps...
            spDrillLoop:stop()
            spDrillEnd:play(1)
        end

        self.isDrilling = false

        if drillableBlockCurrentlyDrilling ~= nil then
            drillableBlockCurrentlyDrilling:release()
            drillableBlockCurrentlyDrilling = nil
        end
    end

    -- Movement handling (update velocity X and Y)

    -- Velocity X

    if not self.isDrilling then
        self:handleHorizontalMovement()
    end

    -- Velocity Y

    if self.onGround then
        self:handleJumpStart()
    else
        self:handleJump()
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

    -- Check if player has moved into another level

    local direction

    if playerX > levelWidth then
        direction = DIRECTION.RIGHT
    elseif playerX < 0 then
        direction = DIRECTION.LEFT
    end

    if playerY > levelHeight then
        direction = DIRECTION.BOTTOM
    elseif playerY + 24 < 0 then -- Add a margin to not trigger level change so easily.
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

        self:moveTo(self.x, levelHeight - 15)
    end

    -- Push level position
    self.checkpointHandler:pushState({
        x = self.x,
        y = self.y,
        blueprints = table.deepcopy(self.blueprints)
    })
end

-- Animation Handling

local flip

function Player:updateAnimationState()
    local animationState

    if self.onGround then
        if self.isDrilling then
            animationState = ANIMATION_STATES.Drilling
        elseif math.floor(math.abs(self.velocity.dx)) > 0 then
            animationState = ANIMATION_STATES.Moving
        else
            animationState = ANIMATION_STATES.Idle
        end
    else
        animationState = ANIMATION_STATES.Jumping
    end

    -- Handle direction (flip)

    flip = 0
    if self.velocity.dx < 0 then
        flip = 1
    elseif self.velocity.dx > 0 then
        flip = 0
    end

    self.states[animationState].flip = flip
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
        self.velocity.dy = -jumpSpeed
        jumpTimeLeftInTicks -= 1
    end
end

function Player:handleJump()
    if self:isJumping() and jumpTimeLeftInTicks > 0 then
        -- Hold Jump
        self.velocity.dy = -jumpSpeed
        self.g_mult = 1
        jumpTimeLeftInTicks -= 1
    elseif pd.buttonJustReleased(KEYNAMES.A) or jumpTimeLeftInTicks > 0 then
        -- Released Jump
        self.g_mult = 5
        jumpTimeLeftInTicks = 0
    end
end

-- Directional

function Player:handleHorizontalMovement()
    if self:isMovingLeft() and self.velocity.dx > -maxSpeed then
        self.velocity.dx -= groundAcceleration
    elseif self:isMovingRight() and self.velocity.dx < maxSpeed then
        self.velocity.dx += groundAcceleration
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
