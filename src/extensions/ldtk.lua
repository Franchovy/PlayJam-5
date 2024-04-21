local pd <const> = playdate
local gfx <const> = pd.graphics
-- Add all layers as tilemaps

function LDtk.loadAllLayersAsSprites(levelName)
    for layerName, layer in pairs(LDtk.get_layers(levelName)) do
        if layer.tiles then
            local tilemap = LDtk.create_tilemap(levelName, layerName)
            local sprite = gfx.sprite.new()
            sprite:setTilemap(tilemap)
            sprite:setCenter(0, 0)
            sprite:moveTo(0, 0)
            sprite:setZIndex(layer.zIndex)
            sprite:add()

            -- TODO: 2 loops? could improve ldtk code
            local solidTiles = LDtk.get_empty_tileIDs(levelName, "Solid", layerName)
            if solidTiles then
                local stiles = gfx.sprite.addWallSprites(tilemap, solidTiles)
                for _, lsprite in ipairs(stiles) do
                  lsprite:setTag(TAGS.Wall)
                end
            end

            local ladderTiles = LDtk.get_empty_tileIDs(levelName, "Ladder", layerName)
            if ladderTiles then
                local ladderSprites = gfx.sprite.addWallSprites(tilemap, ladderTiles)
                for _, lsprite in ipairs(ladderSprites) do
                  lsprite:setTag(TAGS.Ladder)
                end
            end
        end
    end
end

function LDtk.loadAllEntitiesAsSprites(game, levelName, startingItem)
    for _, entity in ipairs(LDtk.get_entities(levelName)) do
        if not _G[entity.name] then
            error("No sprite class for entity with name: " .. entity.name)
        end

        local sprite
    -- wow I'm a good programmer
        if entity.name == "Player" then
          sprite = Player(startingItem)
        else
          sprite = _G[entity.name](game, entity)
        end

        sprite:moveTo(entity.position.x, entity.position.y)
        sprite:setCollideRect(0, 0, entity.size.width, entity.size.height)
        sprite:setCenter(entity.center.x, entity.center.y)
        sprite:setZIndex(entity.zIndex)
        sprite:add()
    end
end
