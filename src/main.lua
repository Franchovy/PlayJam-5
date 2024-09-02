import "const"
import "debug"
import "assets"
import "libs"
import "playdate"
import "extensions"
import "rooms"
import "utils"
import "sprites"

local gfx <const> = playdate.graphics
local timer <const> = playdate.timer

-- Playdate config

local fontDefault = gfx.font.new("assets/fonts/m42.TTF-7")
gfx.setFont(fontDefault)

gfx.setBackgroundColor(0)
gfx.clear(0)

-- Set up Scene Manager (Roomy)

local manager = Manager()

manager:hook()

-- Get levels available

local levels = ReadFile.getLevelFiles()

-- Open Menu (& save reference)

manager.scenes = {
  menu = Menu(levels)
}

manager:enter(manager.scenes.menu)

local last_time = 0

local function updateDeltaTime()
  local current_time = playdate.getCurrentTimeMilliseconds();
  _G.delta_time = (current_time - last_time) / 100;
  last_time = current_time;
end

function playdate.update()
  updateDeltaTime();

  -- Update sprites
  gfx.sprite.update()
  timer.updateTimers()
  gfx.animation.blinker.updateAll()

  -- Update Scenes using Scene Manager
  manager:emit(EVENTS.Update)
end
