local gfx <const> = playdate.graphics

local imageSprite = gfx.image.new("assets/images/drillableblock")

class("DrillableBlock").extends(ConsumableSprite)

local maxTicksToDrill = 15

function DrillableBlock:init(entity)
    DrillableBlock.super.init(self, entity)

    self:setImage(imageSprite)
    self:setTag(TAGS.DrillableBlock)

    self.ticksToDrill = 0

    -- Update variable to track if block is being actively drilled

    self.isActivating = false
end

function DrillableBlock:activate()
    if self.ticksToDrill >= maxTicksToDrill then
        self:consume()
    else
        self.ticksToDrill += 1

        self.isActivating = true
    end
end

function DrillableBlock:reset()
    self.ticksToDrill = 0
end

function DrillableBlock:update()
    -- If a drilling has ended early, reset
    if not self.isActivating and self.ticksToDrill > 0 then
        self:reset()
    end

    self.isActivating = false
end

function DrillableBlock:handleCheckpointRevert(state)
    DrillableBlock.super.handleCheckpointRevert(self, state)

    self:reset()
end
