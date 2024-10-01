local fileplayer <const> = playdate.sound.fileplayer

---@class FilePlayer
---@field fileplayer playdate.sound.fileplayer
---@field fileCurrent string currently playing file
FilePlayer = Class("FilePlayer")

--- Used so that static class syntax looks like it uses instance.
local self = FilePlayer

function FilePlayer.play(file)
    if self.fileCurrent == file then
        return
    end

    self.fileCurrent = file
    self.fileplayer = fileplayer.new(file)
    self.fileplayer:play(0)
end

function FilePlayer.stop()
    if self.fileplayer then
        self.fileplayer:stop()
    end
end

function FilePlayer.isPlaying()
    return self.fileplayer and self.fileplayer:isPlaying()
end