local pd <const> = playdate
local gfx <const> = playdate.graphics

local imageTableWarp <const> = gfx.imagetable.new(assets.imageTables.warp)
local angleCrankToWarpTotal <const> = 6 * 360
local coefficientResistanceCrankMomentum <const> = 0.3
local speedAutoCrankMomentum <const> = 5

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
    [animationStates.start] = 90,
    [animationStates.loop] = 60,
    [animationStates.finish] = 30,
    [animationStates.complete] = 1
}

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
end

function CrankWarpController:isActive()
    return self.state ~= animationStates.complete
end

function CrankWarpController:handleCrankChange()
    if self.state == animationStates.complete then
        self.state = animationStates.start
    end

    -- Get crank change
    local crankChange = pd.getCrankChange()

    -- Increment totalCrankAngleToWarp

    self.crankMomentum += crankChange

    -- If in state start or loop, apply resistance backwards.
    local resistanceCrankMomentum = (speedAutoCrankMomentum - self.crankMomentum) * coefficientResistanceCrankMomentum
    self.crankMomentum -= resistanceCrankMomentum

    print(self.crankMomentum)
    -- Update index
    --self.index = math.floor(self.index - self.crankMomentum / #imageTableWarp)

    -- Get whether a warp has happened
    local hasWarped = self.index <= 1

    return hasWarped
end

function CrankWarpController:resetCrankChange()
    self.index = animationStates.start
end

function CrankWarpController:updateIndex()
    local index = self.index

    if self.state == animationStates.start and self.index <= indexesImageTableWarp[animationStates.loop] then
        -- Transition to loop state
        self.state = animationStates.loop
    end

    if self.state == animationStates.finish and self.index <= indexesImageTableWarp[animationStates.complete] then
        -- Transition to complete
        self.state = animationStates.complete
    end

    if self.state == animationStates.loop and self.index <= indexesImageTableWarp[animationStates.finish] then
        -- Loop current animation
        index = indexesImageTableWarp[animationStates.loop]
    end

    if self.state == animationStates.complete then
        -- Set index to restart
        index = indexesImageTableWarp[animationStates.start]
    end

    self.index = index
end

function CrankWarpController:updateImage()
    self:setImage(imageTableWarp[self.index])
end