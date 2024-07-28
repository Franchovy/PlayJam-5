-- LinkedList data structure - used specifically for checkpoint state tracking

-- Example structure:
-- {
--     [last] = 7
--     [1] = { state1, prev = nil }
--     [3] = { state2, prev = 1 }
--     [7] = { state3, prev = 3 }
-- }

class("LinkedList").extends()

function LinkedList:init(state, index)
    self[index] = {
        state = state,
        prev = nil
    }
    self.last = index or 1
end

function LinkedList:append(state, index)
    if self.last == index then
        -- Update latest state
        self[index].state = state
    else
        -- Create new state
        self[index] = {
            state = state,
            prev = self.last
        }
        self.last = index
    end
end

function LinkedList:pop()
    local index = self.last

    if index == nil then
        -- List is now empty.
        return
    end

    local element = self[index]

    self[index] = nil
    self.last = element.prev
    return element.state
end

function LinkedList:getLast()
    local index = self.last

    if index == nil then
        -- List is empty
        return index
    end

    local element = self[index]
    return element.state
end
