local gfx <const> = playdate.graphics;

class('ButtonPickup').extends(gfx.sprite)

function ButtonPickup:init(entity)
  self.fields = entity.fields

  if self.fields.pickedUp then
    return
  end

  self.abilityName = self.fields.button
  assert(KEYNAMES[self.fields.button], "Missing Key name.")

  local abilityImage = gfx.image.new("assets/images/" .. self.abilityName)
  assert(abilityImage)
  self:setImage(abilityImage)

  self:setTag(TAGS.Ability)
end

function ButtonPickup:pickUp()
  self.fields.pickedUp = true
  self:remove()
end
