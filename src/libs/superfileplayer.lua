-- SuperFilePlayer, by Franchovy
-- Written on Sunday 21 April 2024 at 7:41 AM with no sleep
-- Hooray for Game Jams!!

local fileplayer <const> = playdate.sound.fileplayer

SuperFilePlayer = {
    fileplayers = {},
    playConfig = {},
}

local currentFilePlayer

local function finishedCallback(fileplayer, i)
    local nextIndex = #SuperFilePlayer.fileplayers < i + 1 and 1 or i + 1

    currentFilePlayer = SuperFilePlayer.fileplayers[nextIndex]
    currentFilePlayer:play(SuperFilePlayer.playConfig[i].repeatCount)
end

function SuperFilePlayer.loadFiles(...)
    for i, path in ipairs({ ... }) do
        local fileplayer = assert(fileplayer.new(path), "No sound file found in " .. path)
        fileplayer:setFinishCallback(finishedCallback, i)

        SuperFilePlayer.fileplayers[i] = fileplayer
    end
end

function SuperFilePlayer.setPlayConfig(...)
    for i, repeatCount in ipairs({ ... }) do
        local config = {
            repeatCount = repeatCount
        }

        SuperFilePlayer.playConfig[i] = config
    end
end

function SuperFilePlayer.play()
    assert(#SuperFilePlayer.fileplayers > 0, "No files to play.")
    assert(#SuperFilePlayer.fileplayers == #SuperFilePlayer.playConfig, "Invalid Config Files.")

    currentFilePlayer = SuperFilePlayer.fileplayers[1]
    currentFilePlayer:play(SuperFilePlayer.playConfig[1].repeatCount)
end

function SuperFilePlayer.stop()
    if currentFilePlayer then
        currentFilePlayer:stopWithoutCallback()
    end

    currentFilePlayer = nil
end
