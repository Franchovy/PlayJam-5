local gfx <const> = playdate.graphics

class("Checkpoint").extends(gfx.sprite)

-- Static properties/methods --

-- Reference to the active checkpoint.
local activeCheckpoint

-- Get latest checkpoint.
function Checkpoint.getLatestCheckpoint()
    return activeCheckpoint
end

-- Instance methods --

function Checkpoint:init(entity)
    self.blueprints = entity.fields.blueprints

    self:setTag(TAGS.Checkpoint)
end

function Checkpoint:activate(currentLevelName)
    self.levelName = currentLevelName

    activeCheckpoint = self
end
