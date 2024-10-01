local pd <const> = playdate
local gfx <const> = playdate.graphics

local imageTableWarp <const> = gfx.imagetable.new(assets.imageTables.warp)
local angleCrankToWarpTotal <const> = 300
local coefficientCrankResistance <const> = 0.3
local maxCrankResistanceStart <const> = 15
local maxCrankResistanceLoop <const> = 25

local animationStates = {
    start = "start",
    loop = "loop",
    finish = "finish",
    complete = "complete"
}

--- Indexes in the `totalCrankAngleToWarp` imagetable. Imagetable
--- works in inverse order, starting at the end and working back to the start.
--- @field start number start index.
local indexesImageTableWarp = {
    [animationStates.start] = 91,
    [animationStates.loop] = 60,
    [animationStates.finish] = 30,
    [animationStates.complete] = 1
}

local function setState(self, state)
    self.index = indexesImageTableWarp[state]
    self.state = state

    if self.state == animationStates.loop then
        -- Reset momentum
        self.crankMomentum = 0
    end
end

---@class CrankWarpController: playdate.graphics.sprite
CrankWarpController = Class("CrankWarpController", gfx.sprite)

function CrankWarpController:init()
    CrankWarpController.super.init(self, imageTableWarp[1])

    self:setScale(2)
    self:add()
    self:setZIndex(99)

    self.state = animationStates.complete
    self.index = indexesImageTableWarp[animationStates.start]
    self.crankMomentum = 0
    self.isLoopingMode = false
end

function CrankWarpController:isActive()
    return self.state == animationStates.loop
end

function CrankWarpController:handleCrankChange()
    if self.state == animationStates.complete then
        self.state = animationStates.start
    end

    if not self.isLoopingMode then
        -- Get crank change
        local crankChange = pd.getCrankChange()

        -- Increment totalCrankAngleToWarp

        self.crankMomentum += crankChange

        -- If in state start, apply resistance backwards.
        local resistanceCrankMomentum = (self.crankMomentum) * coefficientCrankResistance
        local maxCrankResistance = self.state == animationStates.start and maxCrankResistanceStart or maxCrankResistanceLoop
        self.crankMomentum = math.max(0, self.crankMomentum - math.min(resistanceCrankMomentum, maxCrankResistance))
    else
        self.crankMomentum = 90
    end

    if self.state == animationStates.start then

        -- Update index
        self.index = indexesImageTableWarp[animationStates.start] - math.floor(self.crankMomentum / angleCrankToWarpTotal * 30)

        if self.index <= indexesImageTableWarp[animationStates.loop] then
            -- Transition to loop state
            setState(self, animationStates.loop)

            -- Reset momentum
            self.crankMomentum = 0
        end
    elseif self.state == animationStates.loop then
        self.index -= 1

        if self.index <= indexesImageTableWarp[animationStates.finish] then
            -- Transition to next state

            -- If crank momentum is high enough, loop again.
            if self.crankMomentum > 60 then
                setState(self, animationStates.loop)
            else
                setState(self, animationStates.finish)
            end
        end
    elseif self.state == animationStates.finish then
        self.index -= 1

        if self.index <= indexesImageTableWarp[animationStates.complete] then
            setState(self, animationStates.complete)
        end
    end

    self:updateImage()

    -- Get whether a warp has happened
    return self.index == indexesImageTableWarp[animationStates.loop]
end

function CrankWarpController:updateImage()
    self:setImage(imageTableWarp[self.index])
end

function CrankWarpController:setLoop()
    self.isLoopingMode = true
    self.state = animationStates.loop
end