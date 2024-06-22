local gfx <const> = playdate.graphics

class("Elevator").extends(RigidBody)

function Elevator:init(entity)
  local imageElevator = gfx.imagetable.new("assets/images/elevator")
  Elevator.super.init(self, entity, imageElevator)

  self.fields = table.deepcopy(entity.fields)
  self:setTag(TAGS.Elevator)

  self:addState("n", 1, 1).asDefault()
  self:playAnimation()
  self.g_mult = 0
  self.inv_mass = 0
  self.actualDistance = self.fields.distance * 32
  self.orientation = self.fields.orientation
end

function Elevator:activate()
  if self.orientation == "Horizontal" then
    if self.x == self.initialX then
      self.targetX = self.x + self.actualDistance
    else
      self.targetX = self.x - self.actualDistance
    end
  elseif self.orientation == "Vertical" then
    if self.y == self.initialY then
      self.targetY = self.y + self.actualDistance
    else
      self.targetY = self.y - self.actualDistance
    end
  end
end

function Elevator:update()
  Elevator.super.update(self)

  if self.targetX > self.x then
    self:moveBy(1, 0)
  elseif self.targetX < self.x then
    self:moveBy(-1, 0)
  end

  if self.targetY > self.y then
    self:moveBy(0, 1)
  elseif self.targetY < self.y then
    self:moveBy(0, -1)
  end
end

function Elevator:add()
  Elevator.super.add(self)
  self.initalX = self.x
  self.initialY = self.y
  self.targetX = self.x
  self.targetY = self.y
  self:activate()
end
