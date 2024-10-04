local pd <const> = playdate
local ds <const> = pd.datastore

class("MemoryCard").extends()

local FILE_NAME <const> = "discontrolled_save_data"

-- local functions, actual data access

local function saveData(data)
  assert(data, "tried to save nil data")
  ds.write(data, FILE_NAME);
end

local function loadData()
  local data = ds.read(FILE_NAME)
  if (data) then return data end
  return {}
end

-- static functions, to be called by other classes

function MemoryCard.setLevelComplete()
  local data = loadData()

  if data == nil or data.lastPlayed == nil then
    return
  end

  if data.levels == nil then
    data.levels = {}
  end

  data.levels[data.lastPlayed] = { complete = true }

  saveData(data)
end

function MemoryCard.getLevelCompleted(level)
  local data = loadData()

  if data.levels == nil or data.levels[level] == nil then
    return false
  end

  return data.levels[level].complete or false
end

function MemoryCard.setLastPlayed(level)
  local data = loadData()
  data.lastPlayed = level
  saveData(data)
end

-- returns world, level representing
-- the last level the player played
function MemoryCard.getLastPlayed()
  local data = loadData()

  if not data.lastPlayed then
    return nil
  end

  -- For backwards-compatibility
  if data.lastPlayed.world and data.lastPlayed.level then
    return nil
  end

  return data.lastPlayed
end

-- returns total, rescued representing
-- the player's progress in a level
function MemoryCard.getLevelCompletion(level)
  local data = loadData()

  if data[level] then
    return 3, data[level].rescued or 0
  end

  return 3, 0
end

function MemoryCard.resetProgress()
  saveData({})
end

-- User Preferences

function MemoryCard.setShouldEnableMusic(shouldEnableMusic)
  local data = loadData()
  data.shouldEnableMusic = shouldEnableMusic
  saveData(data)
end

function MemoryCard.getShouldEnableMusic()
  local data = loadData()

  if data.shouldEnableMusic ~= nil then
    return data.shouldEnableMusic
  end

  return true
end