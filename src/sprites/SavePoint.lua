local gfx <const> = playdate.graphics

local imageTableSprite <const> = gfx.imagetable.new(assets.imageTables.guiRescueBots)
local spWin <const> = playdate.sound.sampleplayer.new(assets.sounds.win)

---@class SavePont: playdate.graphics.sprite
SavePoint = Class("SavePoint", gfx.sprite)

function SavePoint:init()
    SavePoint.super.init(self, imageTableSprite[1])
    -- Sprite Config

    self:setCenter(0, 0.5)
    self:setScale(2)
    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.SavePoint)

    -- State properties

    self.isActivated = false
end

function SavePoint:activate()
    if self.isActivated then
        return
    end

    -- Activate / save game
    self.isActivated = true

    spWin:play(1)

    self:setImage(imageTableSprite[2])
end