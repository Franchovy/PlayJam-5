local gfx <const> = playdate.graphics
local sound <const> = playdate.sound

class("GameComplete").extends(Room)

local spButton
local sp
local fileplayer
local imagetableBgSprite
local bgSprite
local sceneManager
local creditsSprite
local imageCreditsSprite

local showingCredits

function GameComplete:enter(previous)
    sceneManager = self.manager

    showingCredits = false

    spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")
    sp = sound.sampleplayer.new("assets/sfx/ButtonSelect")
    fileplayer = sound.fileplayer.new("assets/music/menu-credits")
    imagetableBgSprite = gfx.imagetable.new("assets/images/gamecomplete-table-400-240")
    bgSprite = AnimatedSprite.new(imagetableBgSprite)

    imageCreditsSprite = gfx.image.new("assets/images/credits")
    creditsSprite = gfx.sprite.new(imageCreditsSprite)

    sp:play()
    fileplayer:play(0)

    bgSprite:add()
    bgSprite:setCenter(0, 0)
    bgSprite:moveTo(0, 0)
    bgSprite:playAnimation()

    creditsSprite:setCenter(0, 0)
    creditsSprite:moveTo(0, 0)
end

function GameComplete:leave(next)
    creditsSprite:remove()
end

function GameComplete:BButtonDown()
    spButton:play(1)

    if not showingCredits then
        bgSprite:remove()
        creditsSprite:add()

        showingCredits = true
    else
        sceneManager:enter(sceneManager.scenes.menu, fileplayer)
    end
end
