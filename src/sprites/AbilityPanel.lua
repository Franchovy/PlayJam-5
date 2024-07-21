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

  -- Add checkpoint state tracking

  self.checkpointHandler = CheckpointHandler()
  self.checkpointHandler:setCheckpointStateHandling(self)
end

-- Override to add button sprites along with sprite.
function AbilityPanel:add()
  AbilityPanel.super.add(self)

  for _, sprite in ipairs(buttonSprites) do
    sprite:add()
  end
end

function AbilityPanel:shake(shakeTime, shakeMagnitude)
  local shakeTimer = pd.timer.new(shakeTime, shakeMagnitude, 0)

  shakeTimer.updateCallback = function(timer)
    local magnitude = math.floor(timer.value)
    local shakeX = math.random(-magnitude, magnitude)
    local shakeY = math.random(-magnitude, magnitude)
    self:moveTo(self.original_x + shakeX, self.original_y + shakeY)
  end

  shakeTimer.timerEndedCallback = function()
    self:moveTo(self.original_x, self.original_y)
  end
end

function AbilityPanel:addItem(item)
  if #items == 3 then
    table.remove(items, 1)
    table.insert(items, item)

    self:updateItemImages()
  else
    table.insert(items, item)

    self:updateItemImages()
  end

  -- Update checkpoint state

  self.checkpointHandler:pushState(table.deepcopy(items))
end

function AbilityPanel:cleanUp()
  self:setItems()

  self:remove()
end

function AbilityPanel:removeRightMost()
  if #items == 1 then
    items[1] = nil
  elseif #items == 2 then
    items[2] = nil
  elseif #items == 3 then
    items[3] = nil
  end

  self:updateItemImages()
end

-- This function serves as a "reset state" function, only to be called by classes like Game on level start.
-- Do not use this to set the items in-game! Instead, set the `items` array directly and call updateItemsCount() & updateItemImages().
function AbilityPanel:setItems(item1, item2, item3)
  items[1] = item1
  items[2] = item2
  items[3] = item3

  self:updateItemImages()

  -- Set initial state reference for checkpoint handling

  self.checkpointHandler:setInitialState(table.deepcopy(items))
end

function AbilityPanel:handleCheckpointStateUpdate(state)
  items[1] = state[1]
  items[2] = state[2]
  items[3] = state[3]

  self:updateItemImages()
end

function AbilityPanel:updateItemImages()
  for i, sprite in ipairs(buttonSprites) do
    if items[i] then
      sprite:add()

      local image = imageTableButtons[imageTableIndexes[items[i]]]
      sprite:setImage(image)
    else
      sprite:remove()
    end
  end
end
