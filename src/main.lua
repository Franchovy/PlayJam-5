import "assets"
import "libs"
import "playdate"
import "extensions"

-- If your LDtk world is saved in multiple files (in this case you see a .ldtkl file for each level in your structure) you need to manually load the levels.
-- LDtk.load_level( "TheFirstLevel" )
-- LDtk.release_level( "TheFirstLevel" )

-- Or, just add wall sprites


-- Entities

--[[
LDtk.get_entities() -- will give you all the entities setup in a level including all their custom fields.

for index, entity in ipairs(LDtk.get_entities("TheFirstLevel")) do
    if entity.name == "Player" then
        player.sprite:add()
        player.init(entity)
    end
end
--]]


LDtk.load(assets.levels.test)

LDtk.loadAllLayersAsSprites("Level_0")

function playdate.update()
    playdate.graphics.sprite.update()
end
