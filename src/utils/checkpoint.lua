-- Checkpoint for Playdate Sprites
-- Allows the game to manage checkpoints via a save state kept within each sprite.

class("Checkpoint").extends()

local checkpointNumber = 0
local checkpointHandlers = table.create(0, 32)
--table.setWeakValueMetatable(checkpointHandlers)

-- Static methods - managing save state at the game level

function Checkpoint.increment()
    checkpointNumber += 1
end

function Checkpoint.goToPrevious()
    for _, handler in pairs(checkpointHandlers) do
        -- ISSUE: See comment.
        handler:revertState()
    end
    checkpointNumber -= 1
end

-- Instance methods - individual sprite methods for managing state

class("CheckpointHandler").extends()

function CheckpointHandler:init(initialState)
    self.initialState = initialState
    self.states = table.create(0, 6)

    table.insert(checkpointHandlers, self)
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
    table.insertUntil(self.states, checkpointNumber, state)
end

function CheckpointHandler:revertState()
    local state
    if checkpointNumber == 0 then
        state = self.initialState
    else
        table.removeUntil(self.states, checkpointNumber)

        local checkpointNumber = checkpointNumber

        -- Decrement through list until it returns a value for the previous state, and initial state if there is none.
        while not state and checkpointNumber > 0 do
            state = self.states[checkpointNumber]
            checkpointNumber -= 1
        end

        if checkpointNumber == 0 then
            state = self.initialState
        end
    end

    -- ISSUE HERE:
    -- The algorithm is returning the most up-to-date checkpoint (e.g. checkpoint no. 3, drilled == true). But actually we want to "pop" the latest checkpoint at checkpoint number
    -- and get the previous state before that checkpoint number.

    if state then
        self.sprite:handleCheckpointStateUpdate(state)
    end
end
