import "const"
import "assets"
import "libs"
import "playdate"
import "extensions"
import "rooms"
import "sprites"


-- Set up Scene Manager (Roomy)

local manager = Manager()
manager:hook()

-- Pre-load levels data

LDtk.load(assets.levels.test)

-- Open Menu (& save reference)

manager.scenes = {
  menu = Menu()
}

manager:enter(manager.scenes.menu)

local last_time = 0

local function updateDeltaTime()
  local current_time = playdate.getCurrentTimeMilliseconds();
  _G.delta_time = (current_time - last_time)/100;
  last_time = current_time;
end

function playdate.update()
  updateDeltaTime();

  -- Update sprites
  playdate.graphics.sprite.update()
  playdate.timer.updateTimers()

  -- Update Scenes using Scene Manager
  manager:emit(EVENTS.Update)
end
