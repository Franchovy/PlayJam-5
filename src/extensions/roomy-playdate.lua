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

-- Static emit function using latest-created sceneManager

function Manager.emitEvent(eventName, ...)
    assert(sceneManager)
    Manager.emit(sceneManager, eventName, ...)
end

function Manager.getInstance()
    return sceneManager
end
