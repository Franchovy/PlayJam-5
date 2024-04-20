local pd <const> = playdate
local gfx <const> = pd.graphics

class("AbilityPanel").extends(pd.graphics.sprite)

local imageUp <const> = gfx.image.new("assets/images/Up")
local imageDown <const> = gfx.image.new("assets/images/Down")
local imageLeft <const> = gfx.image.new("assets/images/Left")
local imageRight <const> = gfx.image.new("assets/images/Right")
local imageA <const> = gfx.image.new("assets/images/A")
local imagePanel <const> = gfx.image.new("assets/images/panel")

function AbilityPanel:init(startingItem)
    AbilityPanel.super.init(self, panel)
    self:add()
end

function AbilityPanel:shake(shakeTime, shakeMagnitude)
    local shakeTimer = pd.timer.new(shakeTime, shakeMagnitude, 0)

    shakeTimer.updateCallback = function(timer)
        local magnitude = math.floor(timer.value)
        local shakeX = math.random(-magnitude, magnitude)
        local shakeY = math.random(-magnitude, magnitude)
        self:moveTo(self.original_x + shakeX, self.original_y + shakeY)
    end

    shakeTimer.timerEndedCallback = function()
        self:moveTo(self.original_x, self.original_y)
    end
end
