local gfx <const> = playdate.graphics

local imageSprite = gfx.image.new("assets/images/drillableblock")

class("DrillableBlock").extends(gfx.sprite)

local maxTicksToDrill = 15

local stateNotDrilled = { drilled = false }
local stateDrilled = { drilled = true }

function DrillableBlock:init(entity)
    DrillableBlock.super.init(self)

    -- Persistent sprite data

    self:setImage(imageSprite)
    self:setTag(TAGS.DrillableBlock)

    self.ticksToDrill = 0

    -- CheckpointHandler for keeping track of state & checkpoint resets

    self.checkpointHandler = CheckpointHandler(self, stateNotDrilled)
end

function DrillableBlock:activate()
    if self.ticksToDrill >= maxTicksToDrill then
        self:updateStateDrilled()
    else
        self.ticksToDrill += 1
    end
end

function DrillableBlock:release()
    self.ticksToDrill = 0
end

function DrillableBlock:updateStateDrilled()
    self.checkpointHandler:pushState(stateDrilled)

    self:remove()
end

function DrillableBlock:handleCheckpointStateUpdate(state)
    if state.drilled then
        self:remove()
    else
        self:add()
    end
end
