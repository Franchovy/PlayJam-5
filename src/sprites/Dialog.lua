local gfx <const> = playdate.graphics


-- Local Constants

local nineSliceSpeech <const> = gfx.nineSlice.new(assets.images.speech, 7, 7, 17, 17)

--

local defaultSize = 16
local textMarginX, textMarginY = 10, 2
local durationDialog = 2000
local collideRectSize = 90
local yOffsetExpanded = 36
--

class("Dialog").extends(gfx.sprite)

function Dialog:init(entity)
    Dialog.super.init(self)

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

    -- Set state

    self.isStateExpanded = false
    self.currentLine = 1
end

function Dialog:draw(x, y, w, h)
    nineSliceSpeech:drawInRect(0, 0, self.width, self.height)

    if self.isStateExpanded then
        local font = gfx.getFont()

        local dialog = self.dialogs[self.currentLine]
        for i, line in ipairs(dialog.lines) do
            font:drawText(line, textMarginX, textMarginY + (i - 1) * font:getHeight())
        end
    end
end

function Dialog:updateDialog()
    local width, height
    if self.isStateExpanded then
        -- Update sprite size using dialog size

        local dialog = self.dialogs[self.currentLine]
        width, height = dialog.width + textMarginX * 2, dialog.height + textMarginY * 2

        -- Set timer to handle next line / collapse
        self.timer = playdate.timer.performAfterDelay(durationDialog, self.showNextLineOrCollapse, self)
    else
        width, height = defaultSize, defaultSize
    end

    self:setSize(width, height)

    -- Update collision rect to keep in the same place
    self:setCollideRect((width - collideRectSize) / 2, (height - collideRectSize) / 2, collideRectSize,
        collideRectSize)

    -- Mark dirty for redraw
    self:markDirty()
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
