local pd <const> = playdate
local ds <const> = pd.datastore

class("MemoryCard").extends()

local FILE_NAME <const> = "discontrolled_save_data"

local DEFAULT_DATA <const> = {
  lastPlayed = { world = 1, level = 1 },
  worlds = {
    [1] = {
      levels = {
        [1] = {
          total = 0,
          rescued = 0
        },
        [2] = {
          total = 0,
          rescued = 0
        },
        [3] = {
          total = 0,
          rescued = 0
        },
        [4] = {
          total = 0,
          rescued = 0
        },
      }
    },
    [2] = {
      levels = {
        [1] = {
          total = 0,
          rescued = 0
        },
        [2] = {
          total = 0,
          rescued = 0
        },
        [3] = {
          total = 0,
          rescued = 0
        },
        [4] = {
          total = 0,
          rescued = 0
        },
      }
    },
    [3] = {
      levels = {
        [1] = {
          total = 0,
          rescued = 0
        },
        [2] = {
          total = 0,
          rescued = 0
        },
        [3] = {
          total = 0,
          rescued = 0
        },
        [4] = {
          total = 0,
          rescued = 0
        },
      }
    },
    [4] = {
      levels = {
        [1] = {
          total = 0,
          rescued = 0
        },
        [2] = {
          total = 0,
          rescued = 0
        },
        [3] = {
          total = 0,
          rescued = 0
        },
        [4] = {
          total = 0,
          rescued = 0
        },
      }
    },
  }
}

-- local functions, actual data access

local function saveData(data)
  assert(data, "tried to save nil data")
  ds.write(data, FILE_NAME);
end

local function loadData()
  local data = ds.read(FILE_NAME)
  if (data) then return data end
  return DEFAULT_DATA
end

-- local functions, helpers

local function assertValidInput(world, level)
  assert(world > 0 and world < 5, "world must be between 1-4 (inclusive)")
  assert(level > 0 and level < 5, "level must be between 1-4 (inclusive)")
end

-- static functions, to be called by other classes

-- sets the total bots for the level
-- ideally called during LDtk loading so
-- it can be done dynamically
function MemoryCard.setTotalBotsForLevel(world, level, total)
  assertValidInput(world, level)
  local data = loadData()
  data.worlds[world].levels[level].total = total
  saveData(data)
end

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
  return data.lastPlayed.world, data.lastPlayed.level
end

-- returns total, rescued representing
-- the player's progress in a level
function MemoryCard.getLevelCompletion(world, level)
  assertValidInput(world, level)
  local data = loadData()
  local r = data.worlds[world].levels[level]
  return r.total, r.rescued
end

function MemoryCard.resetProgress()
  saveData(DEFAULT_DATA)
end
