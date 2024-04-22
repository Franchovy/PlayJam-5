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
local fromMenu

function GameComplete:enter(previous, argFromMenu)
    sceneManager = self.manager

    showingCredits = false

    fromMenu = argFromMenu or false

    spButton = sound.sampleplayer.new("assets/sfx/ButtonSelect")
    sp = sound.sampleplayer.new("assets/sfx/ButtonSelect")
    imagetableBgSprite = gfx.imagetable.new("assets/images/gamecomplete-table-400-240")
    bgSprite = AnimatedSprite.new(imagetableBgSprite)

    imageCreditsSprite = gfx.image.new("assets/images/credits")
    creditsSprite = gfx.sprite.new(imageCreditsSprite)

    sp:play()

    if not fromMenu then
        fileplayer = sound.fileplayer.new("assets/music/menu-credits")
        fileplayer:play(0)
    end

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
        if fromMenu then
            Manager.getInstance():pop()
        else
            sceneManager:enter(sceneManager.scenes.menu, fileplayer)
        end
    end
end
