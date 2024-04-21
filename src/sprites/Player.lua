local pd <const> = playdate
local gmt <const> = pd.geometry
local gfx <const> = pd.graphics
local kCollisionTypeSlide <const> = pd.graphics.sprite.kCollisionTypeSlide

local ANIMATION_STATES = {
    Idle = 1,
    Moving = 2,
    Jumping = 3
}

local STATE = {
    InAir = 1,
    Jumping = 2,
    OnGround = 3,
    OnLadderTop = 4,
    OnLadder = 5
}

-- debug
local debugStateReverse = {}
for k, state in pairs(STATE) do debugStateReverse[state] = k end

KEYS = {
    [KEYNAMES.Up] = pd.kButtonUp,
    [KEYNAMES.Down] = pd.kButtonDown,
    [KEYNAMES.Left] = pd.kButtonLeft,
    [KEYNAMES.Right] = pd.kButtonRight,
    [KEYNAMES.A] = pd.kButtonA,
    [KEYNAMES.B] = pd.kButtonB
}

local maxSpeed <const> = 4.5
local maxSpeedVertical <const> = 3.5
local gravity <const> = 1.6
local maxFallSpeed <const> = 7.5
local jumpSpeed <const> = 7.5
local jumpSpeedReleased <const> = 3.5
local jumpHoldTimeInTicks <const> = 4

-- Setup

class("Player").extends(AnimatedSprite)

function Player:init(entity)
    local playerImageTable = gfx.imagetable.new("assets/images/boseki-table-32-32")
    Player.super.init(self, playerImageTable)

    self:addState(ANIMATION_STATES.Idle, 1, 4, { tickStep = 2 }).asDefault()
    self:addState(ANIMATION_STATES.Moving, 5, 6, { tickStep = 2 })
    self:addState(ANIMATION_STATES.Jumping, 7, 11, { tickStep = 2 })
    self:playAnimation()

    self.state = STATE.OnGround
    self.isDroppingItem = false

    -- Setup keys array and starting keys
    self.keys = {}
    local startingKeys = entity.fields.type
    for _, key in ipairs(startingKeys) do
        table.insert(self.keys, key)
    end

    self.abilityCount = #self.keys

    Manager.emitEvent(EVENTS.LoadItems, table.unpack(startingKeys))
end

function Player:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Wall then
        return gfx.sprite.kCollisionTypeSlide
    else
        return gfx.sprite.kCollisionTypeOverlap
    end
end

-- Update Method

local velocityX = 0
local velocityY = 0
local jumpTimeLeftInTicks = jumpHoldTimeInTicks

function Player:dropLastItem()
    if self.abilityCount == 1 then
        return
    end

    self.isDroppingItem = true
    table.remove(self.keys, self.abilityCount)
    self.abilityCount = self.abilityCount - 1;
    Manager.emitEvent(EVENTS.CrankDrop)

    local dropOffPoints = gmt.polygon.new(self.x+15, self.y+15, self.x+30, self.y+240)
    local sprite = gfx.sprite.new(gfx.image.new("assets/images/A"))
    sprite:setZIndex(100)
    sprite:add()
    sprite:setAnimator(gfx.animator.new(800, dropOffPoints, pd.easingFunctions.inBack))

    pd.timer.new(1500, function()
        self.isDroppingItem = false
        sprite:removeAnimator()
        sprite:remove()
    end)
end

function Player:update()
    -- Crank

    local _, acceleratedChange = pd.getCrankChange()
    if acceleratedChange > 75 and not self.isDroppingItem then
        self:dropLastItem()
    end

    -- Show panel on B

    if self:isShowingInventory() then
        Manager.emitEvent(EVENTS.ShowPanel, true)
    else
        Manager.emitEvent(EVENTS.ShowPanel, false)
    end

    -- Movement handling (update velocity X and Y)

    -- Velocity X

    velocityX = 0

    self:handleHorizontalMovement()

    -- Velocity Y

    if self.state == STATE.OnLadder or self.state == STATE.OnLadderTop then
        velocityY = 0
    end

    if self.state == STATE.OnLadderTop or self.state == STATE.OnGround then
        jumpTimeLeftInTicks = jumpHoldTimeInTicks
    elseif self.state == STATE.OnLadder or self.state == STATE.InAir then
        jumpTimeLeftInTicks = 0
    end

    if self.state == STATE.OnLadder then
        self:handleUpMovement()
        self:handleDownMovement()
    elseif self.state == STATE.OnLadderTop then
        self:handleJumpStart()
        self:handleDownMovement()
    elseif self.state == STATE.OnGround then
        self:handleJumpStart()
    elseif self.state == STATE.InAir then
        self:handleGravity()
    elseif self.state == STATE.Jumping then
        self:handleJump()
    end

    -- Collision Handling

    local targetX, targetY = self.x + velocityX, self.y + velocityY
    local actualX, actualY, collisions, length = self:checkCollisions(targetX, targetY)

    local onGround = false
    local onLadder = false
    local onLadderTop = false

    for _, collisionData in pairs(collisions) do
        local other = collisionData.other
        local tag = other:getTag()
        local type = collisionData.type
        local normal = collisionData.normal
        local position = collisionData.touch
        local overlaps = collisionData.overlaps

        if (type == kCollisionTypeSlide and normal.y == -1) then
            onGround = true
        elseif tag == TAGS.Ladder then
            local otherTop = other.y - other.height - LADDER_TOP_ADJUSTMENT
            local topDetectionRangeMargin = 2.5

            if actualY < position.y - topDetectionRangeMargin and not overlaps then
                -- Player is jumping or moving down
            elseif actualY > otherTop + topDetectionRangeMargin then
                onLadder = true
            elseif position.y <= otherTop + topDetectionRangeMargin and position.y >= otherTop - topDetectionRangeMargin then
                onLadderTop = true

                actualY = otherTop + LADDER_TOP_ADJUSTMENT
            end
        elseif tag == TAGS.Ability then
            Manager.emitEvent(EVENTS.Pickup, other)

            if self.abilityCount == 3 then
                table.remove(self.keys, 1)
            end

            table.insert(self.keys, other.abilityName)
            self.abilityCount = #self.keys
        elseif tag == TAGS.Door then
            Manager.emitEvent(EVENTS.LevelComplete)
        end
    end

    if onLadder then
        self.state = STATE.OnLadder
    elseif onLadderTop then
        self.state = STATE.OnLadderTop
    elseif onGround then
        self.state = STATE.OnGround
    elseif self.state == STATE.Jumping then
        self.state = STATE.Jumping
    else
        self.state = STATE.InAir
    end

    -- Movement

    self:moveTo(actualX, actualY)

    -- Animation Handling

    self:updateAnimationState(self.state)
    self:updateAnimation()
end

-- Animation Handling

local flip

function Player:updateAnimationState(stateCurrent)
    local animationState

    -- Idle/moving (on ground)

    if stateCurrent == STATE.OnGround or stateCurrent == STATE.OnLadderTop then
        if math.abs(velocityX) > 0 then
            animationState = ANIMATION_STATES.Moving
        else
            animationState = ANIMATION_STATES.Idle
        end
    end

    -- In Air / Jumping

    if stateCurrent == STATE.OnLadder then
        animationState = ANIMATION_STATES.Idle
    elseif stateCurrent == STATE.Jumping then
        animationState = ANIMATION_STATES.Jumping
    elseif stateCurrent == STATE.InAir then
        animationState = ANIMATION_STATES.Jumping
    end

    -- Handle direction (flip)

    if velocityX < 0 then
        flip = 1
    elseif velocityX > 0 then
        flip = 0
    end

    self.states[animationState].flip = flip
    self:changeState(animationState)
end

-- Movement Handlers --

-- Jump

function Player:handleJumpStart()
    if pd:buttonJustPressed(pd.kButtonA) and self:isJumping() then
        velocityY = -jumpSpeed
        jumpTimeLeftInTicks -= 1

        self.state = STATE.Jumping
    end
end

function Player:handleJump()
    if self:isJumping() and jumpTimeLeftInTicks > 0 then
        -- Hold Jump
        velocityY = -jumpSpeed
        jumpTimeLeftInTicks -= 1
    elseif jumpTimeLeftInTicks > 0 then
        -- Released Jump
        velocityY = -jumpSpeedReleased
        jumpTimeLeftInTicks = 0
    end

    if jumpTimeLeftInTicks == 0 then
        -- Jump End
        self.state = STATE.InAir
    end
end

-- Gravity

function Player:handleGravity()
    velocityY = math.min(velocityY + gravity, maxFallSpeed)
end

-- Directional

function Player:handleHorizontalMovement()
    if self:isMovingLeft() then
        velocityX = -maxSpeed
    elseif self:isMovingRight() then
        velocityX = maxSpeed
    end
end

function Player:handleUpMovement()
    if self:isMovingUp() then
        velocityY = -maxSpeedVertical
    end
end

function Player:handleDownMovement()
    if self:isMovingDown() then
        velocityY = maxSpeedVertical
    end
end

-- Input Handlers

function Player:isShowingInventory()
    return self:isKeyPressedGated(KEYNAMES.B)
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

    for _, abilityName in ipairs(self.keys) do
        if abilityName == key then
            return pd.buttonIsPressed(abilityName)
        end
    end
    return false
end
