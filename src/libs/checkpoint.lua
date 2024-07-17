-- Checkpoint for Playdate Sprites
-- Allows the game to manage checkpoints via a save state kept within each sprite.

class("Checkpoint").extends()

local checkpointNumber = 0

-- Static methods - managing save state at the game level

function Checkpoint.increment()
    checkpointNumber += 1

    print("Checkpoint number: ", checkpointNumber)
end

function Checkpoint.goToPrevious()
    checkpointNumber -= 1

    print("Checkpoint number: ", checkpointNumber)
end

-- Instance methods - individual sprite methods for managing state

class("CheckpointHandler").extends()

function CheckpointHandler:init(initialState)
    self.initialState = initialState
    self.states = table.create(0, 6)
end

-- Init / Setup methods

function CheckpointHandler:setInitialState(initialState)
    self.initialState = initialState
end

function CheckpointHandler:setCheckpointStateHandling(sprite)
    self.sprite = sprite
end

-- State change methods

function CheckpointHandler:pushState(state)
    self.states[checkpointNumber] = state
end

function CheckpointHandler:revertState()
    return self.states[checkpointNumber]
end
