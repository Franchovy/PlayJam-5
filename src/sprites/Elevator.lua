local gfx <const> = playdate.graphics
local gmt <const> = playdate.geometry
local timer <const> = playdate.timer

class("Elevator").extends(RigidBody)

local maxVelocity = 5
local speed = 1

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
  self.restitution = 0.0
end

function Elevator:activate()
  if self.isActivating or self.isMovingToTarget then return end
  self.isActivating = true

  timer.performAfterDelay(400, function()
    if self.orientation == "Horizontal" then
      if self.x == self.initialX then
        self.targetX = self.x - self.actualDistance
      else
        self.targetX = self.x + self.actualDistance
      end
    elseif self.orientation == "Vertical" then
      if self.y == self.initialY then
        self.targetY = self.y - self.actualDistance
      else
        self.targetY = self.y + self.actualDistance
      end
    end
    -- self.isActivating = false
  end
  )
end

function Elevator:update()
  Elevator.super.update(self)
  local cvx, cvy = self.velocity:unpack()

  local distance = 0

  if self.orientation == "Horizontal" then
    distance = math.abs(self.targetX - self.x)
    if self.targetX > self.x and math.abs(cvx) < maxVelocity then
      self.isMovingToTarget = true
      self.velocity = self.velocity + gmt.vector2D.new(speed, 0);
    elseif self.targetX < self.x and math.abs(cvx) < maxVelocity then
      self.isMovingToTarget = true
      self.velocity = self.velocity + gmt.vector2D.new(-speed, 0);
    end

    if distance < math.abs(self.velocity.dx) then
      self:moveTo(self.targetX, self.targetY);
      self.isMovingToTarget = false
      self.velocity = gmt.vector2D.new(0, 0)
    end
  end

  if self.orientation == "Vertical" then
    distance = math.abs(self.targetY - self.y)
    if self.targetY > self.y and math.abs(cvy) < maxVelocity then
      self.isMovingToTarget = true
      self.velocity = self.velocity + gmt.vector2D.new(0, speed);
    elseif self.targetY < self.y and math.abs(cvy) < maxVelocity then
      self.isMovingToTarget = true
      self.velocity = self.velocity + gmt.vector2D.new(0, -speed);
    end

    if distance < math.abs(self.velocity.dy) then
      self:moveTo(self.targetX, self.targetY);
      self.isMovingToTarget = false
      self.velocity = gmt.vector2D.new(0, 0)
    end
  end
end

function Elevator:add()
  Elevator.super.add(self)
  self.initialX = self.x
  self.initialY = self.y
  self.targetX = self.x
  self.targetY = self.y
end
