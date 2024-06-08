class("Vector").extends()

function Vector:init(x, y)
  Vector.super.init(self)
  self.x = x
  self.y = y
end

function Vector:cross(other)
  return self.x * other.y - self.y * other.x;
end

function Vector:add(other)
  return Vector(self.x + other.x, self.y + other.y)
end

function Vector:subtract(other)
  return Vector(self.x - other.x, self.y - other.y)
end

function Vector:divide(by)
  return Vector(self.x / by, self.y / by)
end

function Vector:multiply(by)
  return Vector(self.x * by, self.y * by)
end

function Vector:getMaginitudeSquare()
end

function Vector:getMagnitude()
end

function Vector:normalize()
  return self:divide()
end
