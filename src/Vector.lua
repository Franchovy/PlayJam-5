class("Vector").extends()

function Vector:init(x, y)
  Vector.super.init(self)
  self.x = x
  self.y = y
end
