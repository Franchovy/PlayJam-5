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

-- Play Music

local fileplayer <const> = playdate.sound.fileplayer.new("assets/music/digit")

assert(fileplayer:play(0))

function playdate.update()
  -- Update Scenes using Scene Manager
  manager:emit(EVENTS.Update)

  -- Update sprites
  playdate.graphics.sprite.update()
end
