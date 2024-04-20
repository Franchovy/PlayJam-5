class("Game").extends(Room)

local levelName <const> = "Level_0"

function Game:enter(previous, ...)
    LDtk.loadAllLayersAsSprites(levelName)
    LDtk.loadAllEntitiesAsSprites(levelName)
end

function Game:update(dt)
    -- update entities
end

function Game:leave(next, ...)
    -- destroy entities and cleanup resources
end

function Game:draw()
    -- draw the level
end
