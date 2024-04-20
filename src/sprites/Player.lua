local gfx <const> = playdate.graphics
local pd <const> = playdate

class("Player").extends(AnimatedSprite)

function Player:init()
    local playerImageTable = gfx.imagetable.new("assets/images/player-table-32-32")
    Player.super.init(self, playerImageTable)

    self:addState("idle", 1, 1)
    self:addState("run", 1, 1)
    self:addState("jump", 1, 1)
    self:addState("climb", 1, 1)
    self:playAnimation()

    self:moveTo(100, 70)
    self:setCollideRect(2, 2, 28, 30)

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
    self.isClimbingLadder = false

    -- abilities
    self.canClimbUp = true
    self.canClimbDown = true
    self.canMoveLeft = false
    self.canMoveRight = true
    self.canPressA = false
    self.canPressB = false

end

function Player:collisionResponse(other)
  self.inFrontOfLadder = false
  if other:getTag() == TAGS.Ability then
    return gfx.sprite.kCollisionTypeOverlap
  elseif other:getTag() == TAGS.Ladder then
    self.inFrontOfLadder = true
    return gfx.sprite.kCollisionTypeOverlap
  else
    return gfx.sprite.kCollisionTypeSlide
  end
end

function Player:update()
    self:updateAnimation()

    self:updateJumpBuffer()
    self:handleState()
    self:handleMovementAndCollisions()
end

function Player:handleState()
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
    elseif self.currentState == "climb" then
        self:handleLadderInput()
    end
end

function Player:updateJumpBuffer()
    self.jumpBuffer -= 1
    if self.jumpBuffer <= 0 then
        self.jumpBuffer = 0
    end
    if pd.buttonJustPressed(pd.kButtonA) then
        self.jumpBuffer = self.jumpBufferAmount
    end
end

function Player:playerJumped()
    return self.jumpBuffer > 0
end

function Player:handleMovementAndCollisions()
    local _, _, collisions, length = self:moveWithCollisions(self.x + self.xVelocity, self.y + self.yVelocity)

    self.touchingGround = false
    self.touchingCeiling = false
    self.touchingWall = false

    for i=1,length do
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
        end
        if collisionTag == TAGS.Ability then
            collisionObject:pickUp(self)
        end
    end

    if(self.touchingGround) then
      self.gravity = 1
    end

    if self.xVelocity < 0 then
        self.globalFlip = 1
    elseif self.xVelocity > 0 then
        self.globalFlip = 0
    end

end

-- Input Helper Functions
function Player:handleGroundInput()
    if self.inFrontOfLadder and pd.buttonJustPressed(pd.kButtonUp) then
        self:changeToClimbState()
    elseif self:playerJumped() and self.canPressA then
        self:changeToJumpState()
    elseif pd.buttonIsPressed(pd.kButtonLeft) and self.canMoveLeft then
        self:changeToRunState("left")
    elseif pd.buttonIsPressed(pd.kButtonRight) and self.canMoveRight then
        self:changeToRunState("right")
    elseif self.touchingGround then
        self:changeToIdleState()
    end
end

function Player:handleLadderInput()
  print("ladder")
    if self.touchingGround and pd.buttonJustReleased(pd.kButtonDown) then
    print("climbing to ground")
        self:changeToIdleState()
        return
    end
    if pd.buttonIsPressed(pd.kButtonUp) and self.canClimbUp then
        self.yVelocity = -self.maxSpeed
    elseif pd.buttonIsPressed(pd.kButtonDown) and self.canClimbDown then
        self.yVelocity = self.maxSpeed
    end
end

function Player:handleAirInput()
    if pd.buttonJustReleased(pd.kButtonA) then
      self.gravity = 1.3
    end
    if pd.buttonIsPressed(pd.kButtonLeft) then
        self.xVelocity = -self.maxSpeed
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        self.xVelocity = self.maxSpeed
    end
end

-- State transitions
function Player:changeToIdleState()
    self.xVelocity = 0
    self:changeState("idle")
end

function Player:changeToRunState(direction)
    if direction == "left" then
        self.xVelocity = -self.maxSpeed
        self.globalFlip = 1
    elseif direction == "right" then
        self.xVelocity = self.maxSpeed
        self.globalFlip = 0
    end
    self:changeState("run")
end

function Player:changeToClimbState()
  print("change to climb state")
    self.isClimbingLadder = true
    self:changeState("climb")
end

function Player:changeToJumpState()
    self.yVelocity = self.jumpVelocity
    self.jumpBuffer = 0
    self:changeState("jump")
end

-- Physics Helper Functions
function Player:applyGravity()
    self.yVelocity += self.gravity
    if self.touchingGround or self.touchingCeiling then
        self.yVelocity = 0
    end
end

function Player:applyDrag(amount)
    if self.xVelocity > 0 then
        self.xVelocity -= amount
    elseif self.xVelocity < 0 then
        self.xVelocity += amount
    end

    if math.abs(self.xVelocity) < self.minimumAirSpeed or self.touchingWall then
        self.xVelocity = 0
    end
end
