-- Checkpoint for Playdate Sprites
-- Allows the game to manage checkpoints via a save state kept within each sprite.

class("Checkpoint").extends()

-- TODO: [FRANCH] - file & API cleanup
-- set sprite in initializer, not in separate fn.

local checkpointNumber = 1
local checkpointHandlers = table.create(0, 32)

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
        if checkpointNumber == 1 then
            print("No state changes detected. Cannot decrement checkpoint number 1.")
            return
        end

        print("No state changes detected. Decrementing the checkpoint number to: " .. checkpointNumber - 1)
        checkpointNumber -= 1

        -- Recursive call to previous checkpoint.
        Checkpoint.goToPrevious()
    end
end

function Checkpoint.getCheckpointNumber()
    return checkpointNumber
end

-- Instance methods - individual sprite methods for managing state

class("CheckpointHandler").extends()

function CheckpointHandler:init(sprite, initialState)
    assert(sprite, "Checkpoint handler needs sprite to initialize.")
    self.sprite = sprite

    if initialState ~= nil then
        self.states = LinkedList(initialState, 0)
    end

    table.insert(checkpointHandlers, self)
end

-- Init / Setup methods

function CheckpointHandler:getState()
    if self.states then
        return self.states:getLast()
    end
end

-- Returns the state for the current checkpoint number, nil if there is no state for that number.
function CheckpointHandler:getStateCurrent()
    if self.states and self.states.last == checkpointNumber then
        return self.states:getLast()
    else
        return nil
    end
end

-- State change methods

function CheckpointHandler:pushState(state)
    if not self.states then
        self.states = LinkedList(table.deepcopy(state), 0)
    end

    self.states:append(state, checkpointNumber)

    print("Pushing state: " .. checkpointNumber)
    printTable(self.states)
end

function CheckpointHandler:revertState()
    assert(self.states)

    local hasChangedState = false

    -- Check what state needs to be reverted.

    print("Checking state to revert: ")
    printTable(self.states)

    -- Pop all values until the checkpoint number.

    local latestCheckpointNumber = self.states.last or 0
    while latestCheckpointNumber >= checkpointNumber do
        self.states:pop()

        latestCheckpointNumber = self.states.last

        -- Mark if state has changed during this revert operation.
        hasChangedState = true
    end

    -- If state changes, get latest state since checkpoint

    if hasChangedState then
        -- TODO: Handling initial state
        local state = self.states:getLast()

        print("Reverting to state: ")
        printTable(state)

        assert(self.sprite.handleCheckpointStateUpdate, "Sprite did not implement handleCheckpointStateUpdate().")
        self.sprite:handleCheckpointStateUpdate(state)
    end

    return hasChangedState
end
