local pd <const> = playdate

local totalCrankAngleToWarp <const> = 6 * 360
local currentCrankAngleTotal = 0

class("CrankWarpController").extends()

function CrankWarpController:init()

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