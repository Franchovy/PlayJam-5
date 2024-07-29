local gfx <const> = playdate.graphics;

class('ButtonPickup').extends(gfx.sprite)

function ButtonPickup:init(entity)
  self.fields = entity.fields

  self.abilityName = self.fields.blueprint
  assert(KEYNAMES[self.abilityName], "Missing Key name.")

  local abilityImage = gfx.image.new("assets/images/" .. self.abilityName)
  assert(abilityImage)
  self:setImage(abilityImage)

  self:setTag(TAGS.Ability)
end

function ButtonPickup:pickUp()
  self.fields.consumed = true
  self:remove()
end
