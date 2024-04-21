-- SuperFilePlayer, by Franchovy
-- Written on Sunday 21 April 2024 at 7:41 AM with no sleep
-- Hooray for Game Jams!!

local fileplayer <const> = playdate.sound.fileplayer

SuperFilePlayer = {
    fileplayers = {},
    playConfig = {}
}

local loops = {}

local function finishedCallback(fileplayer, i)
    print("Loop: " .. i)

    if loops[i] then
        loops[i] += 1
    else
        loops[i] = 1
    end

    if loops[i] == SuperFilePlayer.playConfig[i].repeatCount then
        local nextIndex = #SuperFilePlayer.fileplayers > i + 1 and i + 1 or 1
        print("Next fileplayer: " .. nextIndex)
        SuperFilePlayer.fileplayers[nextIndex]:play()
        loops[i] = 0
    end
end

function SuperFilePlayer.loadFiles(...)
    for i, file in ipairs({ ... }) do
        local fileplayer = fileplayer.new(file)
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

    SuperFilePlayer.fileplayers[1]:play(SuperFilePlayer.playConfig[1].repeatCount)
end
