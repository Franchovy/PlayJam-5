local gfx <const> = playdate.graphics


-- Local Constants

local nineSliceSpeech <const> = gfx.nineSlice.new(assets.images.speech, 7, 7, 17, 17)

--

local defaultSize = 16
local textMarginX, textMarginY = 6, 3

--

class("Dialog").extends(gfx.sprite)

function Dialog:init(entity)
    Dialog.super.init(self)

    -- Get text from LDtk entity

    local text = entity.fields.text
    assert(text)

    -- Break up text into lines

    self.lines = {}
    for line in string.gmatch(text, "([^\n]+)") do
        table.insert(self.lines, line)
    end

    -- Calculate text size using font

    local font = gfx.getFont()

    -- Getting height is easy

    self.textHeight = font:getHeight() * #self.lines

    -- Get max width by line

    self.textWidth = 0
    for _, line in pairs(self.lines) do
        local lineWidth = font:getTextWidth(line)
        if lineWidth > self.textWidth then
            self.textWidth = lineWidth
        end
    end

    -- Set state

    self:setIsCollapsed(false)
    self.currentLine = 1
end

function Dialog:draw(x, y, w, h)
    if isStateCollapsed then
        nineSliceSpeech:drawInRect(0, 0, self.width, self.height)
    else
        nineSliceSpeech:drawInRect(0, 0, self.textWidth, self.textHeight)

        local font = gfx.getFont()
        font:drawText(self.lines[1], textMarginX, textMarginY)
    end
end

function Dialog:update()
    --self:markDirty()
end

function Dialog:setIsCollapsed(isCollapsed)
    if isCollapsed then
        self:setSize(defaultSize, defaultSize)
    else
        self:setSize(self.textWidth + textMarginX * 2, self.textHeight + textMarginY * 2)
    end

    self.isStateCollapsed = isCollapsed
    self:markDirty()
end
