-- Checkpoint for Playdate Sprites
-- Allows the game to manage checkpoints via a save state kept within each sprite.

class("Checkpoint").extends()

local checkpointNumber = 1
local checkpointHandlers = table.create(0, 32)

--- TASK PROGRESS:
-- Insights into the checkpoint system:
-- DONE: 1 - The checkpoint number increment must be done AFTER the button pickup to ensure correct reset.
-- TODO: 2 - The checkpoint number should only increment AFTER a pushState update since the last buttonPickup.
-- TODO: 3 - Need to take advantage of the array-style table formatting for proper index management. Stack pushes and store indexes e.g. (1, state).

-- linkedlist data structure

-- [last] = 7
-- [1] = { state, prev = nil }
-- [3] = { state, prev = 1 }
-- [7] = { state, prev = nil }

function createLinkedList(state, index)
    return { [index] = { [1] = state }, last = index or 1 }
end

function appendLinkedList(list, state, index)
    list[index] = { state, prev = list.last }
    list.last = index
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
    return element[1]
end

function getLastLinkedList(list)
    local index = list.last

    if index == nil then
        -- List is empty
        return index
    end

    local element = list[index]
    return element[1]
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

    assert(testList[16][1][1] == "newState4")
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
    self.states = createLinkedList(initialState, 0)

    table.insert(checkpointHandlers, self)
end

-- Init / Setup methods

function CheckpointHandler:setInitialState(initialState)
    self.states = createLinkedList(initialState, 0)
end

function CheckpointHandler:setCheckpointStateHandling(sprite)
    self.sprite = sprite
end

-- State change methods

function CheckpointHandler:pushState(state)
    appendLinkedList(self.states, state, checkpointNumber)

    print("Pushing state: " .. checkpointNumber)
    printTable(self.states)
end

function CheckpointHandler:revertState()
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

--[[ Numerical indexing (works for multiple Ability Panel)

local latestCheckpointNumber = #self.states
while latestCheckpointNumber >= checkpointNumber do
    self.states[latestCheckpointNumber] = nil
    latestCheckpointNumber = #self.states

    -- Mark if state has changed during this revert operation.
    hasChangedState = true
end

-- If state changes, get latest state since checkpoint

if hasChangedState then
    local state = self.states[#self.states] or self.initialState

--]]
