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
  if self.isActivating or self.isMovingToTarget or self.isDeactivating then return end
  self.isActivating = true

  local slop = 7

  timer.performAfterDelay(400, function()
    if self.orientation == "Horizontal" then
      if math.abs(self.x - self.initialX) <= slop then
        self.targetX = self.x - self.actualDistance
      else
        self.targetX = self.x + self.actualDistance
      end
    elseif self.orientation == "Vertical" then
      if math.abs(self.y - self.initialY) <= slop then
        self.targetY = self.y - self.actualDistance
      else
        self.targetY = self.y + self.actualDistance
      end
    end
    self.isActivating = false
  end
  )
end

function Elevator:update()
  -- don't call SUPER update here, as that does collision work
  -- and we just want to call `moveTo` for the elevator
  -- Elevator.super.update(self)
  if self.isDeactivating or self.isActivating then return end

  local newPos = gmt.vector2D.new(self.x, self.y) + (self.velocity * _G.delta_time)
  self:moveTo(newPos.dx, newPos.dy)
  local cvx, cvy = self.velocity:unpack()

  local distance = 0
  local slop = 1

  if self.orientation == "Horizontal" then
    if self.currentDirection == 1 then
      distance = self.targetX - self.x
    else
      distance = self.x - self.targetX
    end
    if distance <= slop and self.isMovingToTarget then
      self:deactivate()
      return
    end

    if self.targetX > self.x and math.abs(cvx) < maxVelocity then
      self.isMovingToTarget = true
      self.currentDirection = 1
      self.velocity = self.velocity + gmt.vector2D.new(speed, 0);
    elseif self.targetX < self.x and math.abs(cvx) < maxVelocity then
      self.isMovingToTarget = true
      self.currentDirection = -1
      self.velocity = self.velocity + gmt.vector2D.new(-speed, 0);
    end
  end

  if self.orientation == "Vertical" then
    if self.currentDirection == 1 then
      distance = self.targetY - self.y
    else
      distance = self.y - self.targetY
    end
    if distance <= slop and self.isMovingToTarget then
      self:deactivate()
      return
    end

    if self.targetY > self.y and math.abs(cvy) < maxVelocity then
      self.isMovingToTarget = true
      self.currentDirection = 1
      self.velocity = self.velocity + gmt.vector2D.new(0, speed);
    elseif self.targetY < self.y and math.abs(cvy) < maxVelocity then
      self.isMovingToTarget = true
      self.currentDirection = -1
      self.velocity = self.velocity + gmt.vector2D.new(0, -speed);
    end
  end

  if not self.isMovingToTarget and (self.targetY ~= self.y or self.targetX ~= self.x) then
    self:deactivate();
  end
end

function Elevator:deactivate()
  local slop = 3
  if math.abs(self.x - self.initialX) <= slop and math.abs(self.y - self.initialY) <= slop then
    self:moveTo(self.initialX, self.initialY)
  else
    if self.orientation == "Horizontal" then
      self:moveTo(self.initialX + self.actualDistance * self.currentDirection, self.initialY);
    else
      self:moveTo(self.initialX, self.initialY + self.actualDistance * self.currentDirection);
    end
  end
  self.velocity = gmt.vector2D.new(0, 0)

  self.isDeactivating = true
  timer.performAfterDelay(400, function()
    self.isMovingToTarget = false
    self.isDeactivating = false
  end)
end

function Elevator:add()
  Elevator.super.add(self)
  self.initialX = self.x
  self.initialY = self.y
  self.targetX = self.x
  self.targetY = self.y
end
