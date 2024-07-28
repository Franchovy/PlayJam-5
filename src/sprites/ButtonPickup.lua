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

local stateNotConsumed = {
  consumed = false
}

local stateConsumed = {
  consumed = true
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

  -- Checkpoint (state handling) setup

  self.checkpointHandler = CheckpointHandler()
  self.checkpointHandler:setInitialState(stateNotConsumed)
  self.checkpointHandler:setCheckpointStateHandling(self)
end

function ButtonPickup:updateStatePickedUp()
  -- Update checkpoint state

  self.checkpointHandler:pushState(stateConsumed)

  -- Update load file state

  self.fields.consumed = true

  self:remove()
end

function ButtonPickup:handleCheckpointStateUpdate(state)
  if state.consumed then
    self:remove()
  elseif self.levelName == Game.getLevelName() then
    self:add()
  end

  -- Update load file state

  self.fields.consumed = state.consumed
end
