local pd <const> = playdate
local gfx <const> = pd.graphics
local kCollisionTypeSlide <const> = pd.graphics.sprite.kCollisionTypeSlide
local kCollisionTypeOverlap <const> = pd.graphics.sprite.kCollisionTypeOverlap

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
local debugReverseState = {}
for k, v in pairs(STATE) do debugReverseState[v] = k end

local maxSpeed <const> = 4.5
local maxSpeedVertical <const> = 3.5
local gravity <const> = 1.6
local maxFallSpeed <const> = 7.5
local jumpSpeed <const> = 7.5
local jumpSpeedReleased <const> = 3.5
local jumpHoldTimeInTicks <const> = 4

-- Setup

class("Player").extends(AnimatedSprite)

function Player:init()
    local playerImageTable = gfx.imagetable.new("assets/images/boseki-table-32-32")
    Player.super.init(self, playerImageTable)

    self:addState(ANIMATION_STATES.Idle, 1, 4, { tickStep = 2 }).asDefault()
    self:addState(ANIMATION_STATES.Moving, 5, 6, { tickStep = 2 })
    self:addState(ANIMATION_STATES.Jumping, 7, 11, { tickStep = 2 })
    self:playAnimation()

    self.state = STATE.OnGround
end

function Player:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Ability or tag == TAGS.Door or tag == TAGS.Ladder then
        return kCollisionTypeOverlap
    else
        return kCollisionTypeSlide
    end
end

-- Update Method

local velocityX = 0
local velocityY = 0
local jumpTimeLeftInTicks = jumpHoldTimeInTicks

function Player:update()
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

    self:updateAnimationState()
    self:updateAnimation()
end

-- Animation Handling

function Player:updateAnimationState()
    if self.onGround or self.onLadder then
        if math.abs(velocityX) > 0 then
            self:changeState(ANIMATION_STATES.Moving)
        else
            self:changeState(ANIMATION_STATES.Idle)
        end
    else
        self:changeState(ANIMATION_STATES.Jumping)
    end
end

-- Movement Handlers --

-- Jump

function Player:handleJumpStart()
    if self:isJumping() then
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

function Player:isJumping()
    return playdate.buttonIsPressed(playdate.kButtonA)
end

function Player:isMovingRight()
    return playdate.buttonIsPressed(playdate.kButtonRight)
end

function Player:isMovingLeft()
    return playdate.buttonIsPressed(playdate.kButtonLeft)
end

function Player:isMovingUp()
    return playdate.buttonIsPressed(playdate.kButtonUp)
end

function Player:isMovingDown()
    return playdate.buttonIsPressed(playdate.kButtonDown)
end
