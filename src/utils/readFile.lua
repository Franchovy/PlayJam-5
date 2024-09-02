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