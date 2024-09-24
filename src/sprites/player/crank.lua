local pd <const> = playdate
local gfx <const> = playdate.graphics

local imageTableWarp <const> = gfx.imagetable.new(assets.imageTables.warp)

local totalCrankAngleToWarp <const> = 6 * 360
local currentCrankAngleTotal = 0

class("CrankWarpController").extends(gfx.sprite)

function CrankWarpController:init()
    CrankWarpController.super.init(self, imageTableWarp[1])

    self:setScale(4)
    self:setCenter(0, 0)
    self:moveTo(0, 0)
    self:add()
    self:setZIndex(99)

    --self:setAlwaysRedraw(true)
    self:setIgnoresDrawOffset(true)
end

function CrankWarpController:handleCrankChange()
    -- Get crank change
    local crankChange = pd.getCrankChange()

    -- Increment totalCrankAngleToWarp
    currentCrankAngleTotal += crankChange

    -- Get whether a warp has happened
    local hasWarped = currentCrankAngleTotal > totalCrankAngleToWarp

    return hasWarped
end

function CrankWarpController:resetCrankChange()
    currentCrankAngleTotal = 0
end

function CrankWarpController:updateImage()
    local index = math.floor(currentCrankAngleTotal / totalCrankAngleToWarp * (#imageTableWarp + 1))

    self:setImage(imageTableWarp[index])
end