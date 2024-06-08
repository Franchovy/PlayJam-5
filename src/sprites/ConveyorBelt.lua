local pd <const> = playdate
local gfx <const> = pd.graphics

class("ConveyorBelt").extends(gfx.sprite)

local width <const> = 32

function ConveyorBelt:init(entity)
  self:setTag(TAGS.ConveyorBelt)
  self.fields = table.deepcopy(entity.fields)
  self.direction = self.fields.ConveyorDirection

  ConveyorBelt.super.init(self)

  local imageTable = gfx.imagetable.new("assets/images/conveyorbelt")
  local tilemap = gfx.tilemap.new()
  tilemap:setImageTable(imageTable)

  local a = {}
  local tileCount = entity.size.width / width
  for i=1, tileCount do
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

