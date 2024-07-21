local gfx <const> = playdate.graphics;

-- FRANCH: This is being initialized twice. What's the best way to have both instances point to the same logic?

local imageTableButtons = gfx.imagetable.new(assets.imageTables.buttons)
local imageTableIndexes = {
  [KEYNAMES.Right] = 1,
  [KEYNAMES.Left] = 2,
  [KEYNAMES.Down] = 3,
  [KEYNAMES.Up] = 4,
  [KEYNAMES.A] = 5,
  [KEYNAMES.B] = 6,
}

class('ButtonPickup').extends(gfx.sprite)

function ButtonPickup:init(entity)
  self.fields = entity.fields

  self.abilityName = self.fields.blueprint
  assert(KEYNAMES[self.abilityName], "Missing Key name: " .. self.abilityName)

  local abilityImage = imageTableButtons[imageTableIndexes[self.abilityName]]
  assert(abilityImage)
  self:setImage(abilityImage)

  self:setTag(TAGS.Ability)
end

function ButtonPickup:pickUp()
  self.fields.consumed = true
  self:remove()
end
