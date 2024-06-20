import "const"
import "assets"
import "libs"
import "playdate"
import "extensions"
import "rooms"
import "sprites"
import "vector"

-- Playdate config

local fontDefault = playdate.graphics.font.new("assets/fonts/m42.TTF-7")
playdate.graphics.setFont(fontDefault)

playdate.graphics.setBackgroundColor(0)
playdate.graphics.clear(0)

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

function playdate.update()
  -- Update sprites
  playdate.graphics.sprite.update()
  playdate.timer.updateTimers()

  -- Update Scenes using Scene Manager
  manager:emit(EVENTS.Update)
end
