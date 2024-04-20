-- Swizzle enter method – adds reference from scene to the manager.
local enterSwizzled = Manager.enter
function Manager.enter(self, next, ...)
    next.manager = self
    enterSwizzled(self, next, ...)
end

local sceneManager = nil

-- Swizzle init method - keep a reference of sceneManager

local managerInitSwizzled = Manager.init
function Manager.init(self, ...)
    managerInitSwizzled(self, ...)

    sceneManager = self
end

-- Static emit function (Manager.emit) using latest-created sceneManager

local emitSwizzled = Manager.emit
function Manager.emit(manager, eventName)
    -- Single arg format, static call
    if not eventName then
        eventName = manager
        manager = sceneManager
    end
    assert(manager)
    emitSwizzled(manager, eventName)
end
