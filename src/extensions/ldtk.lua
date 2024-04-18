-- Add all layers as tilemaps

function LDtk.loadAllLayersAsSprites(levelName)
    for layerName, layer in pairs(LDtk.get_layers(levelName)) do
        if layer.tiles then
            local tilemap = LDtk.create_tilemap(levelName, layerName)
            local sprite = playdate.graphics.sprite.new()
            sprite:setTilemap(tilemap)
            sprite:setCenter(0, 0)
            sprite:moveTo(0, 0)
            sprite:setZIndex(layer.zIndex)
            sprite:add()

            local emptyTiles = LDtk.get_empty_tileIDs()
            if emptyTiles then
                playdate.graphics.sprite.addWallSprites(tilemap, emptyTiles)
            end
        end
    end
end
