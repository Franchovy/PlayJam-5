local pd <const> = playdate
local gfx <const> = pd.graphics
-- Add all layers as tilemaps

function LDtk.loadAllLayersAsSprites(levelName, levelX, levelY)
    local hintCrank = LDtk.get_custom_data(levelName, "HintCrank")
    for layerName, layer in pairs(LDtk.get_layers(levelName)) do
        if layer.tiles then
            local tilemap = LDtk.create_tilemap(levelName, layerName)
            local sprite = gfx.sprite.new()
            sprite:setTilemap(tilemap)
            sprite:setCenter(0, 0)
            sprite:moveTo(0, 0)
            sprite:setZIndex(layer.zIndex)
            sprite:add()

            local solidTiles = LDtk.get_empty_tileIDs(levelName, "Solid", layerName)
            if solidTiles then
                local stiles = gfx.sprite.addWallSprites(tilemap, solidTiles)
                for _, lsprite in ipairs(stiles) do
                    lsprite:setTag(TAGS.Wall)
                end
            end
        end
    end
    return hintCrank
end

function LDtk.loadAllEntitiesAsSprites(levelName)
    for _, entity in ipairs(LDtk.get_entities(levelName)) do
        if not _G[entity.name] then
            print("WARNING: No sprite class for entity with name: " .. entity.name)

            goto continue
        end

        -- If Player already exists and is playing, then don't create a new player.
        if entity.name == "Player" and Player.getInstance() then
            goto continue
        end

        -- If sprite has been marked "consumed" then we shouldn't add it in. (e.g. DrillableBlock, ButtonPickup)
        if entity.fields.consumed == true then
            goto continue
        end

        local sprite = _G[entity.name](entity)
        sprite:moveTo(entity.position.x, entity.position.y)

        if entity.name == "Player" then
            -- Reduce hitbox sizes
            local trimWidth, trimTop = 6, 8
            sprite:setCollideRect(trimWidth, trimTop, sprite.width - trimWidth * 2, sprite.height - trimTop)
        else
            sprite:setCollideRect(0, 0, entity.size.width, entity.size.height)
        end
        sprite:setCenter(entity.center.x, entity.center.y)
        sprite:setZIndex(entity.zIndex)
        sprite:add()

        sprite.levelName = levelName

        ::continue::
    end
end
