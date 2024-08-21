local sound <const> = playdate.sound
local gfx <const> = playdate.graphics

local spCheckpointRevert <const> = sound.sampleplayer.new(assets.sounds.checkpointRevert)
local imageTable <const> = gfx.imagetable.new(assets.imageTables.warpTransition)


-- Timer for handling cooldown on checkpoint revert

local timerCooldownCheckpoint
local crankCooldown = false

local numberOfFullCrankRotationsForWarp <const> = 2
local cooldownAmountInDegreesPerSecond <const> = 20

class("WarpTransition").extends(gfx.sprite)

function WarpTransition:init()
    WarpTransition.super.init(self)

    self:setCenter(0, 0)
    self:moveTo(0, 0)
    self:setIgnoresDrawOffset(true)
    self:setZIndex(100)

    self.percentageCompleteInDegrees = 0
    self.index = 1

    self:updateImage()
end

function WarpTransition:updateImage()
    print(self.index)
    
    self:setImage(imageTable[self.index])
end

function WarpTransition:update()
    local rotationChangeInDegrees = playdate.getCrankChange() / numberOfFullCrankRotationsForWarp

    -- Update rotation percentage complete 

    if rotationChangeInDegrees > 0 then
        -- Add crank change to percentage complete
        self.percentageCompleteInDegrees = math.min(self.percentageCompleteInDegrees + rotationChangeInDegrees, 360)
    elseif self.percentageCompleteInDegrees > 0 then
        -- Apply "Cooldown", reduce percentage complete
        self.percentageCompleteInDegrees = math.max(
            self.percentageCompleteInDegrees - 
            cooldownAmountInDegreesPerSecond * _G.delta_time,
            0
        )
    end

    -- Translate rotation in percentage to an index for imageTable

    local index = math.floor(self.percentageCompleteInDegrees / 360 * #imageTable) + 1

    -- If crankCooldown is in progress, end cooldown if index is 0.
    if crankCooldown and index == 1 then
        crankCooldown = false

        -- Emit event
        Manager.emitEvent(EVENTS.CheckpointRevertCooldownFinished)
    end

    if index == #imageTable then
        -- If max index is reached, trigger revert checkpoint

        self:revertCheckpoint()

        -- Reset index and percentage complete

        self.index = 0
        self.percentageCompleteInDegrees = 0

    elseif index ~= self.index then
        -- Else if index has changed, update the image accordingly

        self.index = index
        self:updateImage()
    end
end


function WarpTransition:revertCheckpoint()

    -- SFX

    spCheckpointRevert:play(1)

    -- Emit the event for the rest of the scene

    Manager.emitEvent(EVENTS.CheckpointRevert)

    -- Cooldown timer for checkpoint revert

    timerCooldownCheckpoint = playdate.timer.new(500)
    timerCooldownCheckpoint.timerEndedCallback = function(timer)
        timer:remove()

        -- Since there can be multiple checkpoint-reverts in sequence, we want to
        -- ensure we're not removing a timer that's not this one.
        if timerCooldownCheckpoint == timer then
            timerCooldownCheckpoint = nil
            crankCooldown = true
        end
    end
end
