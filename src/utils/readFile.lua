local file <const> = playdate.file

ReadFile = {}

function ReadFile.getLevelFiles()
    -- Get the level files
    local files = file.listFiles(assets.path.levels)

    local levels = {}

    -- Filter files to just .ldtk suffix
    for _, filename in pairs(files) do
        if string.match(filename, '(.ldtk)$') then

            table.insert(levels, string.sub(filename, 1, #filename - 5))
        end
    end

    return levels
end

function ReadFile.getLevel(world, level)
    -- Get the level files
    local files = file.listFiles(assets.path.levels)

    local levelFile = nil

    for _, filename in pairs(files) do
        -- find .ldtk files that match the convention and the given world/level
        if string.match(filename, '^World '..world..'%-'..level..'.+%.ldtk') then
          -- don't break the loop - there may be a 'v2' coming, assuming listFiles is alpha-sorted
          levelFile = filename
        end
    end

    return levelFile
end
