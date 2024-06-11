local gfx <const> = playdate.graphics

local imageSprite = gfx.image.new("assets/images/drillableblock")

class("DrillableBlock").extends(gfx.sprite)

local maxTicksToDrill = 15

function DrillableBlock:init()
    DrillableBlock.super.init(self)

    self:setImage(imageSprite)

    self:setTag(TAGS.DrillableBlock)

    self.ticksToDrill = 0
end

function DrillableBlock:activate()
    if self.ticksToDrill >= maxTicksToDrill then
        self:remove()
    else
        self.ticksToDrill += 1
    end
end

function DrillableBlock:release()
    self.ticksToDrill = 0
end
