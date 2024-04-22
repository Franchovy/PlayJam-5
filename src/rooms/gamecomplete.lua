local gfx <const> = playdate.graphics
local sound <const> = playdate.sound

class("GameComplete").extends(Room)

local spButton
local sp
local fileplayer
local imagetable
local bgSprite
local sceneManager

function GameComplete:enter(previous)
    sceneManager = self.manager

    spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")
    sp = sound.sampleplayer.new("assets/sfx/ButtonSelect")
    fileplayer = sound.fileplayer.new("assets/music/menu-credits.wav")
    bgSprite = AnimatedSprite.new(imagetable)
    imagetable = gfx.imagetable.new("assets/images/gamecomplete")

    sp:play()
    fileplayer:play(0)

    bgSprite:add()
    bgSprite:playAnimation()
end

function GameComplete:leave(next)

end

function Menu:BButtonDown()
    spButton:play(1)
    sceneManager.scenes.howto = HowTo()
    sceneManager:push(sceneManager.scenes.howto)
end
