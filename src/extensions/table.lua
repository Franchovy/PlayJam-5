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
