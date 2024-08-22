local pd <const> = playdate
local gfx <const> = pd.graphics

class("ConveyorBelt").extends(AnimatedSprite)

function ConveyorBelt:init(entity)
  local imageTable = gfx.imagetable.new("assets/images/conveyorbelt")
  ConveyorBelt.super.init(self, entity, imageTable)

  self:setTag(TAGS.ConveyorBelt)

  -- LDtk fields

  self.fields = table.deepcopy(entity.fields)

  -- Create tilemap from imagetable

  local tilemap = gfx.tilemap.new()
  tilemap:setImageTable(imageTable)

  local a = {}
  local tileCount = entity.size.width / TILE_SIZE
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

  -- RigidBody config -- TODO - switch to RigidBodyInteractible

  self.rigidBody = RigidBody(self)
end

function ConveyorBelt:collisionResponse(_)
  return gfx.sprite.kCollisionTypeSlide
end

function ConveyorBelt:getAppliedSpeed()
  return self.fields.direction == "Right" and 1 or -1;
end

function ConveyorBelt:update()
  self.rigidBody:update()
end
