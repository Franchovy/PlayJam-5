local gfx <const> = playdate.graphics


-- Local Variables

-- Assets

local imageSpeech <const> = gfx.image.new(assets.images.speech)
local nineSliceSpeech <const> = gfx.nineSlice.new(assets.images.speech, 7, 7, 17, 17)
local spSpeech <const> = playdate.sound.sampleplayer.new(assets.sounds.speech)

-- Constants

local defaultSize <const> = 16
local textMarginX <const>, textMarginY <const> = 10, 2
local durationDialog <const> = 3000
local collideRectSize <const> = 90
local yOffset <const> = 16

-- Child class functions

local function drawSpeechBubble(self, x, y, w, h)
    -- Draw Speech Bubble

    nineSliceSpeech:drawInRect(0, 0, self.width, self.height)

    -- Draw Text

    if self.dialog then
        local font = gfx.getFont()

        for i, line in ipairs(self.dialog.lines) do
            font:drawText(line, textMarginX, textMarginY + (i - 1) * font:getHeight())
        end
    end
end


--

class("Dialog").extends(gfx.sprite)

function Dialog:init(entity)
    Dialog.super.init(self, imageSpeech)

    -- Sprite setup

    self:setTag(TAGS.Dialog)

    -- Get text from LDtk entity

    local text = entity.fields.text
    assert(text)

    -- Get font used for calculating text size

    local font = gfx.getFont()

    -- Break up text into lines

    self.dialogs = {}
    for text in string.gmatch(text, "([^\n]+)") do
        local dialog = {
            text = text,
            lines = {},
            width = 0,
            height = 0
        }

        for text in string.gmatch(text, "[^/]+") do
            -- Get dialog width by getting max width of all lines
            local textWidth = font:getTextWidth(text)
            if dialog.width < textWidth then
                dialog.width = textWidth
            end

            -- Add line to dialog lines
            table.insert(dialog.lines, text)
        end

        -- Add dialog height based on num. lines
        dialog.height = font:getHeight() * #dialog.lines

        -- Add dialog to list
        table.insert(self.dialogs, dialog)
    end

    -- Set up child sprite

    self.spriteBubble = gfx.sprite.new()
    self.spriteBubble.draw = drawSpeechBubble
    self.spriteBubble:moveTo(self.x, self.y)
    self.spriteBubble:add()

    -- Set state

    self.isStateExpanded = false
    self.currentLine = 1
end

function Dialog:postInit()
    -- Set collide rect to full size, centered on current center.
    self:setCollideRect(
        (self.width - collideRectSize) / 2,
        (self.height - collideRectSize) / 2,
        collideRectSize,
        collideRectSize
    )
end

function Dialog:updateDialog()
    if self.isStateExpanded then
        -- Update sprite size using dialog size

        local dialog = self.dialogs[self.currentLine]

        -- Set timer to handle next line / collapse
        self.timer = playdate.timer.performAfterDelay(durationDialog, self.showNextLineOrCollapse, self)

        -- Update child sprite dialog
        self.spriteBubble.dialog = dialog

        -- Set size and position
        local width, height = dialog.width + textMarginX * 2, dialog.height + textMarginY * 2
        self.spriteBubble:setSize(width, height)
        self.spriteBubble:moveTo(self.x, self.y - height - yOffset)
    else
        self.spriteBubble.dialog = nil
        self.spriteBubble:setSize(defaultSize, defaultSize)
        self.spriteBubble:moveTo(self.x, self.y)
    end

    -- Mark dirty for redraw
    self.spriteBubble:markDirty()
end

function Dialog:showNextLineOrCollapse()
    if self.currentLine < #self.dialogs then
        -- Show next line
        self.currentLine += 1
    else
        -- Collapse
        self:collapse()
    end
end

function Dialog:expand()
    if self.isStateExpanded then
        return
    end

    self.isStateExpanded = true

    -- Play SFX
    spSpeech:play(1)
end

function Dialog:collapse()
    -- Set state to collapsed

    self.isStateExpanded = false
    self.currentLine = 1

    -- Stop any ongoing timers

    self.timer:pause()
end

function Dialog:update()
    if self.isStateExpandedPrevious ~= self.isStateExpanded
        or self.currentLinePrevious ~= self.currentLine then
        self:updateDialog()
    end

    self.isStateExpandedPrevious = self.isStateExpanded
    self.currentLinePrevious = self.currentLine
end
