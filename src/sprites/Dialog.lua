local gfx <const> = playdate.graphics


-- Local Constants

local nineSliceSpeech <const> = gfx.nineSlice.new(assets.images.speech, 7, 7, 17, 17)

--

local defaultSize = 16
local textMarginX, textMarginY = 10, 2
local durationDialog = 3000

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

function Dialog:postInit()
    self:setCollideRect(-30, -30, defaultSize + 60, defaultSize + 60)
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
    if self.isStateExpanded then
        local dialog = self.dialogs[self.currentLine]
        self:setSize(dialog.width + textMarginX * 2, dialog.height + textMarginY * 2)

        -- Set timer to handle next line / collapse
        self.timer = playdate.timer.performAfterDelay(durationDialog, self.showNextLineOrCollapse, self)
    else
        self:setSize(defaultSize, defaultSize)
    end

    -- Mark dirty for redraw
    self:markDirty()
end

function Dialog:showNextLineOrCollapse()
    if self.currentLine < #self.dialogs then
        -- Show next line
        self.currentLine += 1
    else
        -- Collapse & Reset
        self.isStateExpanded = false
        self.currentLine = 1

        self:reset()
    end
end

function Dialog:expand()
    if self.isStateExpanded then
        return
    end

    self.isStateExpanded = true
end

function Dialog:update()
    if self.isStateExpandedPrevious ~= self.isStateExpanded
        or self.currentLinePrevious ~= self.currentLine then
        self:updateDialog()
    end

    self.isStateExpandedPrevious = self.isStateExpanded
    self.currentLinePrevious = self.currentLine
end
