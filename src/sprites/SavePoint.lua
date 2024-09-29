local gfx <const> = playdate.graphics

local imageTableSprite <const> = gfx.imagetable.new(assets.imageTables.guiRescueBots)
local spWin <const> = playdate.sound.sampleplayer.new(assets.sounds.win)
local spError <const> = playdate.sound.sampleplayer.new(assets.sounds.errorSavePoint)

---@class SavePont: playdate.graphics.sprite
SavePoint = Class("SavePoint", gfx.sprite)

function SavePoint:init(entity)
    SavePoint.super.init(self, imageTableSprite[1])

    -- Entity Config

    self.blueprints = entity.fields.blueprints

    -- Sprite Config

    self:setCenter(0, 0.5)
    self:setScale(2)
    self:setCollideRect(0, 0, self:getSize())
    self:setTag(TAGS.SavePoint)

    -- State properties

    self.isActivated = false
    self.blueprintsCurrentError = nil
end

function SavePoint:update()
    if self.blinkerError then
        if self.blinkerError.on then
            self:setImage(imageTableSprite[1])
        else
            self:setImage(imageTableSprite[2])
        end

        if not self.blinkerError.running then
            self.blinkerError = nil
        end
    end
end

function SavePoint:activate()
    if self.isActivated then
        return
    end

    local player = Player.getInstance()
    local blueprintsPlayer = player.blueprints

    if self.blueprintsCurrentError == blueprintsPlayer then
        return
    end

    -- Check if blueprints match

    local isMatchBlueprints = true
    for i,blueprint in ipairs(self.blueprints) do
        isMatchBlueprints = isMatchBlueprints and blueprintsPlayer[i] == blueprint
    end

    if isMatchBlueprints then
        -- Activate / save game
        self.isActivated = true

        spWin:play(1)

        self:setImage(imageTableSprite[2])

        Checkpoint.clearAllPrevious()
    else
        self.blueprintsCurrentError = blueprintsPlayer

        self.blinkerError = gfx.animation.blinker.new(30, 40, false, 14, true)
        self.blinkerError:start()

        spError:play(1)
    end
end