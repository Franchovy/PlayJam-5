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

SuperFilePlayer.loadFiles("assets/music/1", "assets/music/2", "assets/music/3", "assets/music/4")
SuperFilePlayer.setPlayConfig(4, 4, 4, 4)

SuperFilePlayer.play()

function playdate.update()
  -- Update Scenes using Scene Manager
  manager:emit(EVENTS.Update)

  -- Update sprites
  playdate.graphics.sprite.update()
end
