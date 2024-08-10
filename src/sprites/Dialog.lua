local gfx <const> = playdate.graphics


-- Local Constants

local nineSliceSpeech <const> = gfx.nineSlice.new(assets.images.speech, 7, 7, 17, 17)

--

local defaultSize = 16
local textMarginX, textMarginY = 10, 2
local maxTextWidth = 200

--

class("Dialog").extends(gfx.sprite)

function Dialog:init(entity)
    Dialog.super.init(self)

    -- Get text from LDtk entity

    local text = entity.fields.text
    assert(text)

    -- Get font used for calculating text size

    local font = gfx.getFont()

    -- Break up text into lines

    self.dialogs = {}
    for text in string.gmatch(text, "([^\n]+)") do
        local dialog = { text = text, lines = {} }

        local maxWidth = 0
        for text in string.gmatch(text, "([^/]+)") do
            -- Get dialog width by getting max width of all lines
            local textWidth = font:getTextWidth(text)
            if maxWidth < textWidth then
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

    self:setIsCollapsed(false)
    self.currentLine = 1
end

function Dialog:draw(x, y, w, h)
    nineSliceSpeech:drawInRect(0, 0, self.width, self.height)

    if not isStateCollapsed then
        local font = gfx.getFont()

        local dialog = self.dialogs[1]
        for i, line in ipairs(dialog.lines) do
            font:drawText(line, textMarginX, textMarginY + (i - 1) * font:getHeight())
        end
    end
end

function Dialog:setIsCollapsed(isCollapsed)
    if isCollapsed then
        self:setSize(defaultSize, defaultSize)
    else
        local dialog = self.dialogs[1]
        self:setSize(dialog.width + textMarginX * 2, dialog.height + textMarginY * 2)
    end

    self.isStateCollapsed = isCollapsed
    self:markDirty()
end
