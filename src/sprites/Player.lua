local gfx <const> = playdate.graphics

class("Player").extends(gfx.sprite)

function Player:init()
    Player.super.init(self)
    print("Created player!")

    local image = gfx.image.new(32, 32)
    image:clear(gfx.kColorBlack)
    self:setImage(image)
end

function Player:update()
    if playdate.buttonIsPressed(playdate.kButtonRight) then
        self:moveBy(5, 0)
    end
end
