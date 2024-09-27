playdate.geometry.vector2D.ZERO = playdate.geometry.vector2D.new(0, 0)

--- Class - creates a class object globally.
--- @param name string name of the class
--- @param parentClass? table (optional) parent class to inherit
--- @return table NewClass class instance.
function Class(name, parentClass)
    local newClass = class(name)
    newClass.extends(parentClass)

    return _G[name]
end
