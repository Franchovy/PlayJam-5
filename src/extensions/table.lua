local weakValueMetatable = { __mode = "v" }
function table.setWeakValueMetatable(t)
    setmetatable(t, weakValueMetatable)
end

local weakKeyMetatable = { __mode = "k" }
function table.setWeakKeyMetatable(t)
    setmetatable(t, weakKeyMetatable)
end

local weakKeyValueMetatable = { __mode = "kv" }
function table.setWeakKeyValueMetatable(t)
    setmetatable(t, weakKeyValueMetatable)
end

-- Fills an array-like table with boolean value *false* until position *pos*, inserting *element* at *pos*.
-- If *pos* is greater than the table length, the function has no effect.
function table.insertUntil(t, pos, element)
    while #t < pos do
        table.insert(t, false)
    end

    if #t == pos then
        table.insert(t, element)
    end
end

-- Removes all elements in an array-like table until position *pos*.
function table.removeUntil(t, pos)
    while #t > pos do
        table.remove(t)
    end

    if #t == pos then
        return t[pos]
    end
end
