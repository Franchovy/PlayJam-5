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

            local emptyTiles = LDtk.get_empty_tileIDs(levelName, "Solid", layerName)
            if emptyTiles then
                playdate.graphics.sprite.addWallSprites(tilemap, emptyTiles)
            end
        end
    end
end

function LDtk.loadAllEntitiesAsSprites(levelName)
    for index, entity in ipairs(LDtk.get_entities(levelName)) do
        if not _G[entity.name] then
            error("No sprite class for entity with name: " .. entity.name)
        end

        local sprite = _G[entity.name](entity.position.x, entity.position.y, entity)
        sprite:setCenter(entity.center.x, entity.center.y)
        sprite:setZIndex(entity.zIndex)
        sprite:add()

        --[[if entity.name=="Player" then
			if entity.fields.EntranceDirection == direction then
				player.sprite:add()
				player.init( entity )
			end
		else
			local entity_image = LDtk.generate_image_from_entity(entity)
			if entity_image then
				local new_deco_sprite = playdate.graphics.sprite.new( entity_image )
				new_deco_sprite:moveTo( entity.position.x, entity.position.y )
				new_deco_sprite:setCenter(0,0)
				new_deco_sprite:add()
			end
		end]]
    end
end
