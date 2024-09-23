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
  return LEVEL_DATA
end

-- local functions, helpers

local function assertValidInput(world, level)
  local isValidInputWorld = world > 0 and world <= #LEVEL_DATA.worlds
  local isValidInputLevel = level > 0 and level <= #LEVEL_DATA.worlds[world].levels

  -- PLAYTESTING: Throw error.
  if BUILD_FLAG.DEBUG or BUILD_FLAG.PLAYTESTING then
    assert(isValidInputWorld, "`world` is out of range.", 2)
    assert(isValidInputLevel, "`level` is out of range.", 2)
  end

  -- DEBUG ONLY: Overwrite level data if data is invalid.
  if BUILD_FLAG.DEBUG then
    local currentData = loadData()
    
    if #currentData.worlds ~= #LEVEL_DATA.worlds or #currentData.worlds[world].levels ~= #LEVEL_DATA.worlds[world].levels then
      saveData(LEVEL_DATA)
    end
  end
end

-- static functions, to be called by other classes

-- sets the rescued bots for the level
-- ideally called when a bot is rescued
function MemoryCard.setRescuedBotsForLevel(world, level, rescued)
  assertValidInput(world, level)
  local data = loadData()
  data.worlds[world].levels[level].rescued = rescued
  saveData(data)
end

function MemoryCard.setLastPlayed(world, level)
  assertValidInput(world, level)
  local data = loadData()
  data.lastPlayed = { world = world, level = level }
  saveData(data)
end

-- returns world, level representing
-- the last level the player played
function MemoryCard.getLastPlayed()
  local data = loadData()
  
  if not data.lastPlayed then
    return nil
  end

  return data.lastPlayed.world, data.lastPlayed.level
end

-- returns total, rescued representing
-- the player's progress in a level
function MemoryCard.getLevelCompletion(world, level)
  assertValidInput(world, level)
  local data = loadData()
  local r = data.worlds[world].levels[level]
  return r.total, r.rescued or 0
end

function MemoryCard.resetProgress()
  saveData(LEVEL_DATA)
end
