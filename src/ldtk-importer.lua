-- You first need to copy the file Ldtk.lua in your playdate project and to import it

import 'LDtk'

-- Next you need to load your main .ldtk file, typically during the game loading

-- LDtk.load("MyWorld.ldtk")
-- If your LDtk world is saved in multiple files (in this case you see a .ldtkl file for each level in your structure) you need to manually load the levels.

-- LDtk.load_level( "TheFirstLevel" )
-- And you can also release the level and the assets used by it.

-- LDtk.release_level( "TheFirstLevel" )
-- It is usually better to load a new level before releasing the previous one because if they share the same asset, these assets will not need to be loaded.

-- Tilemap
-- When you want to finally use a level in your game, you need to create the playdate tilemap object
-- LDtk.create_tilemap( "TheFirstLevel" )

-- Collisions
-- You can also query the tiles using enum values you have setup in your Ldtk world using LDtk.get_tileIDs() but to generate collision the Playdate SDK requires tiles that are should by empty so `LDtk.get_empty_tileIDs() should be used instead.

--[[
local tilemap = LDtk.create_tilemap("TheFirstLevel", "gameplay_layer")
playdate.graphics.sprite.addWallSprites(tilemap, LDtk.get_empty_tileIDs("TheFirstLevel", "Solid", "gameplay_layer"))
--]]

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
