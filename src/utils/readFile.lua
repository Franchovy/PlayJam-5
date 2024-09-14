local file <const> = playdate.file

ReadFile = {}

function ReadFile.getLevelFiles()
    -- Get the level files
    local files = file.listFiles(assets.path.levels)

    -- Filter files to just .ldtk suffix
    local levels = {}

    for _, filename in pairs(files) do
        if string.match(filename, '(.ldtk)$') then
            table.insert(levels, filename)
        end
    end

    return levels
end

function ReadFile.getLevel(world, level)
    -- Get the level files
    local files = file.listFiles(assets.path.levels)

    -- Filter files to just .ldtk suffix
    local levelFile = nil

    for _, filename in pairs(files) do
        if string.match(filename, '^World '..world..'%-'..level..'.+%.ldtk') then
          -- don't break the loop - there may be a 'v2' coming, adduming listFiles is alpha-sorted
          levelFile = filename
        end
    end

    return levelFile
end
