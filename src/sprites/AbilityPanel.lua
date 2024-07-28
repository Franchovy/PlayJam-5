local pd <const> = playdate
local gfx <const> = pd.graphics
local gmt <const> = pd.geometry

class("AbilityPanel").extends(pd.graphics.sprite)

local imagePanel <const> = gfx.image.new(assets.images.hudPanel)

-- Button images (from imagetable)

local imageTableButtons = gfx.imagetable.new(assets.imageTables.buttons)
local imageTableIndexes = {
  [KEYNAMES.Right] = 1,
  [KEYNAMES.Left] = 2,
  [KEYNAMES.Down] = 3,
  [KEYNAMES.Up] = 4,
  [KEYNAMES.A] = 5,
  [KEYNAMES.B] = 6,
}

local items = {}

local buttonSprites = table.create(3, 0)
for i = 1, 3 do
  table.insert(buttonSprites, gfx.sprite.new())
end

local spritePositions = {
  gmt.point.new(16, 14),
  gmt.point.new(42, 14),
  gmt.point.new(68, 14),
}

-- Static Reference

local _instance

function AbilityPanel.getInstance() return _instance end

--

function AbilityPanel:init()
  AbilityPanel.super.init(self, imagePanel)
  _instance = self

  self:setCenter(0, 0)
  self:moveTo(0, 0)
  self:setZIndex(99)
  self:add()
  self:setIgnoresDrawOffset(true)

  for i, sprite in ipairs(buttonSprites) do
    sprite:moveTo(spritePositions[i]:unpack())
    sprite:setZIndex(100)
    sprite:add()
    sprite:setIgnoresDrawOffset(true)
  end

  self:setUpdatesEnabled(false)
end

-- Override to add button sprites along with sprite.
function AbilityPanel:add()
  AbilityPanel.super.add(self)

  for _, sprite in ipairs(buttonSprites) do
    sprite:add()
  end
end

function AbilityPanel:cleanUp()
  self:setItems()

  self:remove()
end

function AbilityPanel:updateBlueprints()
  local blueprints = Player.getInstance().blueprints
  self.blueprints = blueprints

  for i, sprite in ipairs(buttonSprites) do
    if blueprints[i] then
      sprite:add()

      local image = imageTableButtons[imageTableIndexes[blueprints[i]]]
      sprite:setImage(image)
    else
      sprite:remove()
    end
  end
end
