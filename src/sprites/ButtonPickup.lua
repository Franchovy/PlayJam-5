local gfx <const> = playdate.graphics;

class('ButtonPickup').extends(gfx.sprite)

function ButtonPickup:init(entity)
  self.fields = table.deepcopy(entity.fields)

  if self.fields.pickedUp then
    return
  end

  self.abilityName = self.fields.button

  local abilityImage = gfx.image.new("assets/images/" .. self.abilityName)
  assert(abilityImage)
  self:setImage(abilityImage)
  self:setCenter(0, 0)
  self:add()

  self:setTag(TAGS.Ability)
  self:setCollideRect(0, 0, self:getSize())
end

function ButtonPickup:pickUp(player)
  if self.abilityName == "Left" then
    player.canMoveLeft = true
  elseif self.abilityName == "Right" then
    player.canMoveRight = true
  elseif self.abilityName == "A" then
    player.canPressA = true
  elseif self.abilityName == "B" then
    player.canPressB = true
  end

  self.fields.pickedUp = true
  self:remove()
end
