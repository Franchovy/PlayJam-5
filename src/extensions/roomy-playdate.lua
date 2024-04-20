-- Swizzle enter method – adds reference from scene to the manager.
local enterSwizzled = Manager.enter
function Manager.enter(self, next, ...)
    next.manager = self
    enterSwizzled(self, next, ...)
end
