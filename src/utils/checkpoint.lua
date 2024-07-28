-- Checkpoint for Playdate Sprites
-- Allows the game to manage checkpoints via a save state kept within each sprite.

class("Checkpoint").extends()

-- TODO: [FRANCH] - file & API cleanup
-- set sprite in initializer, not in separate fn.
-- separate out linkedlist struct

local checkpointNumber = 1
local checkpointHandlers = table.create(0, 32)

--- TASK PROGRESS:
-- Insights into the checkpoint system:
-- DONE: 1 - The checkpoint number increment must be done AFTER the button pickup to ensure correct reset.
-- TODO: 2 - The checkpoint number should only increment AFTER a pushState update since the last buttonPickup.
-- DONE: 3 - Need to take advantage of the array-style table formatting for proper index management. Stack pushes and store indexes e.g. (1, state).

-- TODO: Move this into another file. Would be great to rewrite data structure code in C or Swift, or at least using a class interface.
-- linkedlist data structure

-- [last] = 7
-- [1] = { state, prev = nil }
-- [3] = { state, prev = 1 }
-- [7] = { state, prev = nil }

function createLinkedList(state, index)
    return {
        [index] = {
            state = state,
            prev = nil
        },
        last = index or 1
    }
end

function appendLinkedList(list, state, index)
    if list.last == index then
        -- Update latest state
        list[index].state = state
    else
        -- Create new state
        list[index] = {
            state = state,
            prev = list.last
        }
        list.last = index
    end
end

function popLinkedList(list)
    local index = list.last

    if index == nil then
        -- List is now empty.
        return
    end

    local element = list[index]

    list[index] = nil
    list.last = element.prev
    return element.state
end

function getLastLinkedList(list)
    local index = list.last

    if index == nil then
        -- List is empty
        return index
    end

    local element = list[index]
    return element.state
end

function testLinkedList()
    local testList = createLinkedList({ "testState" }, 3)
    appendLinkedList(testList, { "newState" }, 5)
    appendLinkedList(testList, { "newState2" }, 9)
    appendLinkedList(testList, { "newState3" }, 17)
    popLinkedList(testList)

    assert(testList[17] == nil)
    assert(testList.last == 9)

    appendLinkedList(testList, { "newState4" }, 16)

    assert(testList[16].state[1] == "newState4")
    assert(testList.last == 16)

    popLinkedList(testList)
    popLinkedList(testList)
    popLinkedList(testList)
    assert(testList.last == 3)

    popLinkedList(testList)
    assert(testList.last == nil)

    popLinkedList(testList) -- Doesn't break
end

testLinkedList()

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

function CheckpointHandler:init(initialState)
    if initialState ~= nil then
        self.states = createLinkedList(initialState, 0)
    end

    table.insert(checkpointHandlers, self)
end

-- Init / Setup methods

function CheckpointHandler:setInitialState(initialState)
    assert(initialState, "Initial state must not be null.")

    self.states = createLinkedList(initialState, 0)
end

function CheckpointHandler:setCheckpointStateHandling(sprite)
    self.sprite = sprite
end

function CheckpointHandler:getState()
    if self.states then
        return getLastLinkedList(self.states)
    end
end

-- Returns the state for the current checkpoint number, nil if there is no state for that number.
function CheckpointHandler:getStateCurrent()
    if self.states and self.states.last == checkpointNumber then
        return getLastLinkedList(self.states)
    else
        return nil
    end
end

-- State change methods

function CheckpointHandler:pushState(state)
    if not self.states then
        self.states = createLinkedList(table.deepcopy(state), 0)
    end

    appendLinkedList(self.states, state, checkpointNumber)
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
        popLinkedList(self.states)

        latestCheckpointNumber = self.states.last

        -- Mark if state has changed during this revert operation.
        hasChangedState = true
    end

    -- If state changes, get latest state since checkpoint

    if hasChangedState then
        -- TODO: Handling initial state
        local state = getLastLinkedList(self.states)

        print("Reverting to state: ")
        printTable(state)

        assert(self.sprite.handleCheckpointStateUpdate, "Sprite did not implement handleCheckpointStateUpdate().")
        self.sprite:handleCheckpointStateUpdate(state)
    end

    return hasChangedState
end
