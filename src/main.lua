import "assets"
import "libs"
import "playdate"
import "extensions"
import "sprites"
import "rooms"


-- Set up Scene Manager (Roomy)

local manager = Manager()
manager:hook()

-- Pre-load levels data

LDtk.load(assets.levels.test)

-- Open Menu
manager:enter(Menu())

-- Play Music

local fileplayer <const> = playdate.sound.fileplayer.new("assets/music/digit")

assert(fileplayer:play(0))

function playdate.update()
    -- Update Scenes using Scene Manager
    manager:emit('update')

    -- Update sprites
    playdate.graphics.sprite.update()
end
