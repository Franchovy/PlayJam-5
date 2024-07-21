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
    print("Performing Checkpoint revert operation...")

    local hasChanged = false
    for _, handler in pairs(checkpointHandlers) do
        local hasChangedNew = handler:revertState()
        hasChanged = hasChanged or hasChangedNew
    end

    -- Only decrement the checkpoint number if no reset occurred.
    if not hasChanged then
        if checkpointNumber == 0 then
            print("No state changes detected. Cannot decrement checkpoint number 0.")
            return
        end

        print("No state changes detected. Decrementing the checkpoint number to: " .. checkpointNumber - 1)
        checkpointNumber -= 1
    end
end

function Checkpoint.getCheckpointNumber()
    return checkpointNumber
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
    self.states[checkpointNumber] = state

    print("Pushing state: " .. checkpointNumber)
    printTable(self.states)
end

function CheckpointHandler:revertState()
    local hasChangedState = false

    -- Check what state needs to be reverted.

    print("Checking state to revert: ")
    printTable(self.states)

    -- Pop all values until the checkpoint number.

    local latestCheckpointNumber = next(self.states) or 0
    while latestCheckpointNumber and latestCheckpointNumber >= checkpointNumber do
        self.states[latestCheckpointNumber] = nil
        latestCheckpointNumber = next(self.states)

        -- Mark if state has changed during this revert operation.
        hasChangedState = true
    end

    -- If state changes, get latest state since checkpoint

    if hasChangedState then
        local state = next(self.states) or self.initialState

        print("Reverting to state: ")
        printTable(state)

        self.sprite:handleCheckpointStateUpdate(state)
    end

    return hasChangedState
end
