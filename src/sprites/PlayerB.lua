local gfx <const> = playdate.graphics
local pd <const> = playdate

class("Playerb").extends(AnimatedSprite)

function Playerb:init()
    local PlayerbImageTable = gfx.imagetable.new("assets/images/Playerb-table-32-32")
    Playerb.super.init(self, PlayerbImageTable)

    self:addState("idle", 1, 1)
    self:addState("run", 1, 1)
    self:addState("jump", 1, 1)
    self:playAnimation()

    self.xVelocity = 0
    self.yVelocity = 0
    self.gravity = 1.0
    self.maxSpeed = 2
    self.jumpVelocity = -10
    self.drag = 0.1
    self.minimumAirSpeed = 0.5

    self.jumpBufferAmount = 5
    self.jumpBuffer = 0

    self.touchingGround = false
    self.touchingWall = false
    self.touchingCeiling = false
    self.inFrontOfLadder = false

    -- abilities
    self.canMoveLeft = false
    self.canMoveRight = true
    self.canPressA = false
    self.canPressB = false
end

function Playerb:collisionResponse(other)
    local tag = other:getTag()
    if tag == TAGS.Ability or tag == TAGS.Door or tag == TAGS.Ladder then
        return gfx.sprite.kCollisionTypeOverlap
    else
        return gfx.sprite.kCollisionTypeSlide
    end
end

function Playerb:update()
    self:updateAnimation()

    self:updateJumpBuffer()
    self:handleState()
    self:handleLadders()
    self:handleMovementAndCollisions()
end

function Playerb:handleState()
    if self.currentState == "idle" then
        self:applyGravity()
        self:handleGroundInput()
    elseif self.currentState == "run" then
        self:applyGravity()
        self:handleGroundInput()
    elseif self.currentState == "jump" then
        if self.touchingGround then
            self:changeToIdleState()
        end
        self:applyGravity()
        self:applyDrag(self.drag)
        self:handleAirInput()
    end
end

function Playerb:updateJumpBuffer()
    self.jumpBuffer -= 1
    if self.jumpBuffer <= 0 then
        self.jumpBuffer = 0
    end
    if pd.buttonJustPressed(pd.kButtonA) then
        self.jumpBuffer = self.jumpBufferAmount
    end
end

function Playerb:PlayerbJumped()
    return self.jumpBuffer > 0
end

function Playerb:handleMovementAndCollisions()
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)

    self.touchingGround = false
    self.touchingCeiling = false
    self.touchingWall = false
    self.inFrontOfLadder = false

    for i = 1, length do
        local collision = collisions[i]
        local collisionType = collision.type
        local collisionObject = collision.other
        local collisionTag = collisionObject:getTag()
        if collisionType == gfx.sprite.kCollisionTypeSlide then
            if collision.normal.y == -1 then
                self.touchingGround = true
            elseif collision.normal.y == 1 then
                self.touchingCeiling = true
            end

            if collision.normal.x ~= 0 then
                self.touchingWall = true
            end
        elseif collisionType == gfx.sprite.kCollisionTypeOverlap then
            if collisionTag == TAGS.Ability then
                collisionObject:pickUp(self)
            elseif collisionTag == TAGS.Door then
                Manager.emit(EVENTS.LevelComplete)
            elseif collisionTag == TAGS.Ladder then
                self.inFrontOfLadder = true
            end
        end
    end

    if (self.touchingGround) then
        self.gravity = 1
    end

    if self.xVelocity < 0 then
        self.globalFlip = 1
    elseif self.xVelocity > 0 then
        self.globalFlip = 0
    end
end

function Playerb:handleLadders()
    if self.inFrontOfLadder then
        if pd.buttonIsPressed(pd.kButtonUp) then
            self.yVelocity = -self.maxSpeed
        elseif pd.buttonIsPressed(pd.kButtonDown) then
            self.yVelocity = self.maxSpeed
        end
    end
end

-- Input Helper Functions
function Playerb:handleGroundInput()
    if self:PlayerbJumped() and self.canPressA then
        self:changeToJumpState()
    elseif pd.buttonIsPressed(pd.kButtonLeft) and self.canMoveLeft then
        self:changeToRunState("left")
    elseif pd.buttonIsPressed(pd.kButtonRight) and self.canMoveRight then
        self:changeToRunState("right")
    elseif self.touchingGround then
        self:changeToIdleState()
    end
end

function Playerb:handleAirInput()
    if pd.buttonJustReleased(pd.kButtonA) and not self.inFrontOfLadder then
        self.gravity = 1.3
    end
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = -self.maxSpeed
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.maxSpeed
    end
end

-- State transitions
function Playerb:changeToIdleState()
    self.xVelocity = 0
    self:changeState("idle")
end

function Playerb:changeToRunState(direction)
    if direction == "left" then
        self.xVelocity = -self.maxSpeed
        self.globalFlip = 1
    elseif direction == "right" then
        self.xVelocity = self.maxSpeed
        self.globalFlip = 0
    end
    self:changeState("run")
end

function Playerb:changeToJumpState()
    self.yVelocity = self.jumpVelocity
    self.jumpBuffer = 0
    self:changeState("jump")
end

-- Physics Helper Functions
function Playerb:applyGravity()
    self.yVelocity += self.gravity
    if self.touchingGround or self.touchingCeiling then
        self.yVelocity = 0
    end
end

function Playerb:applyDrag(amount)
    if self.xVelocity > 0 then
        self.xVelocity -= amount
    elseif self.xVelocity < 0 then
        self.xVelocity += amount
    end

    if math.abs(self.xVelocity) < self.minimumAirSpeed or self.touchingWall then
        self.xVelocity = 0
    end
end
