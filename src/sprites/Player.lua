local gfx <const> = playdate.graphics
local pd <const> = playdate

local STATES = {
    Ground = 1,
    Ladder = 2,
    Air = 3
}

local maxSpeed = 5

class("Player").extends(AnimatedSprite)

function Player:init()
    local playerImageTable = gfx.imagetable.new("assets/images/boseki-table-32-32")
    Player.super.init(self, playerImageTable)

    self:addState("idle", 1, 4, { tickStep = 2 }).asDefault()
    self:addState("run", 5, 6, { tickStep = 2 })
    self:addState("jump", 7, 11, { tickStep = 2 })
    self:playAnimation()

    self.state = STATES.Ground
end

function Player:collisionResponse()
    local tag = other:getTag()
    if tag == TAGS.Ability or tag == TAGS.Door or tag == TAGS.Ladder then
        return gfx.sprite.kCollisionTypeOverlap
    else
        return gfx.sprite.kCollisionTypeSlide
    end
end

function Player:update()
    local velocityX = 0
    local velocityY = 0

    if self.state == STATES.Ground then
        velocityY = 0

        if self:isMovingLeft() then
            velocityX = -maxSpeed
        elseif self:isMovingRight() then
            velocityX = maxSpeed
        end
    end

    local targetX, targetY = self.x + velocityX, self.y + velocityY
    local actualX, actualY, collisions, length = self:checkCollisions(targetX, targetY)

    self:moveTo(actualX, actualY)

    self:updateAnimation()
end

function Player:isMovingRight()
    return playdate.buttonIsPressed(playdate.kButtonRight)
end

function Player:isMovingLeft()
    return playdate.buttonIsPressed(playdate.kButtonLeft)
end
