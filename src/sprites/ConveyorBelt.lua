local pd <const> = playdate
local gfx <const> = pd.graphics

class("ConveyorBelt").extends(RigidBody)

local width <const> = 32

function ConveyorBelt:init(entity)
  local imageTable = gfx.imagetable.new("assets/images/conveyorbelt")
  ConveyorBelt.super.init(self, entity, imageTable)

  self.g_mult = 0
  self.inv_mass = 0
  self.dynamic_friction = 0

  self:setTag(TAGS.ConveyorBelt)
  self.fields = table.deepcopy(entity.fields)
  self.restitution = .3

  local tilemap = gfx.tilemap.new()
  tilemap:setImageTable(imageTable)

  local a = {}
  local tileCount = entity.size.width / width
  for i = 1, tileCount do
    if i == 1 then
      a[i] = 1
    elseif i == tileCount then
      a[i] = 3
    else
      a[i] = 2
    end
  end
  tilemap:setTiles(a, entity.size.width)
  self:setTilemap(tilemap);
end

function ConveyorBelt:getDirection()
  return self.fields.direction;
end
