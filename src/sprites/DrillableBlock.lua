local gfx <const> = playdate.graphics

local imageSprite = gfx.image.new("assets/images/drillableblock")

class("DrillableBlock").extends(ConsumableSprite)

local maxTicksToDrill = 15

function DrillableBlock:init(entity)
    DrillableBlock.super.init(self, entity)

    -- Persistent sprite data

    self.fields = entity.fields

    self:setImage(imageSprite)
    self:setTag(TAGS.DrillableBlock)

    self.ticksToDrill = 0
end

function DrillableBlock:activate()
    if self.ticksToDrill >= maxTicksToDrill then
        self:consume()
    else
        self.ticksToDrill += 1
    end
end

function DrillableBlock:release()
    self.ticksToDrill = 0
end

function DrillableBlock:handleCheckpointRevert(state)
    DrillableBlock.super.handleCheckpointRevert(self, state)

    -- Reset time to drill
    self.ticksToDrill = 0
end
