local pd <const> = playdate
local gfx <const> = pd.graphics
local sound <const> = pd.sound

class("Game").extends(Room)

local sceneManager
local systemMenu <const> = pd.getSystemMenu()

local fileplayer

-- LDtk current level name

local initialLevelName <const> = "Level_0"
local currentLevelName
local checkpointPlayerStart

local spriteLevelCompleteText
local spriteLevelCompleteHintText
local blinkerLevelComplete

-- Sprites

local botsToRescueCount <const> = 3
local spriteGuiRescueCounter

-- Static methods

function Game.getLevelName()
    return currentLevelName
end

-- Private Methods

local function goToStart()
    sceneManager:enter(sceneManager.scenes.start)
end

-- Instance methods

function Game:init()
    self.checkpointHandler = CheckpointHandler.getOrCreate("game", self)

    spriteLevelCompleteText = gfx.sprite.spriteWithText("Level Complete", 200, 80, nil, nil, nil, kTextAlignment.center)
    spriteLevelCompleteText:setScale(1.5)
    spriteLevelCompleteText:getImage():setInverted(true)
    spriteLevelCompleteText:moveTo(200, 60)
    spriteLevelCompleteText:setIgnoresDrawOffset(true)

    spriteLevelCompleteHintText = gfx.sprite.spriteWithText("Crank to Finish", 200, 80, nil, nil, nil, kTextAlignment.center)
    spriteLevelCompleteHintText:getImage():setInverted(true)
    spriteLevelCompleteHintText:moveTo(200, 90)
    spriteLevelCompleteHintText:setIgnoresDrawOffset(true)

    blinkerLevelComplete = gfx.animation.blinker.new(700, 300, true)
end

function Game:enter(previous, data)
    data = data or {}
    local direction = data.direction
    local level = data.level
    local isCheckpointRevert = data.isCheckpointRevert

    -- Load rescuable bot array

    if data.isInitialLoad then
        local botRescueCount = botsToRescueCount

        -- Set up GUI

        local spriteRescueCounter = SpriteRescueCounter.getInstance()

        if not spriteRescueCounter then
            spriteRescueCounter = SpriteRescueCounter()
        end

        spriteRescueCounter:setRescueSpriteCount(botRescueCount)
    end

    -- This should run only once to initialize the game instance.

    if not self.isInitialized then
        self.isInitialized = true

        -- Set local reference to sceneManager

        sceneManager = self.manager
        sceneManager.scenes.currentGame = self

        -- Load Ability Panel

        self.abilityPanel = AbilityPanel()

        -- Menu items

        systemMenu:addMenuItem("back to start", goToStart)
    end

    -- Load level --

    currentLevelName = level and level.name or initialLevelName
    local levelBounds = level and level.bounds or LDtk.get_rect(currentLevelName)

    if not isCheckpointRevert then
        self.checkpointHandler:pushState({ levelName = currentLevelName })
    end

    LDtk.loadAllLayersAsSprites(currentLevelName)

    LDtk.loadAllEntitiesAsSprites(currentLevelName)

    local player = Player.getInstance()

    if player then
        player:add()

        if checkpoint then
            player:setBlueprints(checkpoint.blueprints)
            player:moveTo(checkpoint.x, checkpoint.y)
        end

        player:enterLevel(direction, levelBounds)
    end

    local abilityPanel = AbilityPanel.getInstance()

    if abilityPanel then
        abilityPanel:add()
    end

    local rescueCounter = SpriteRescueCounter.getInstance()

    if rescueCounter then
        rescueCounter:add()
    end
end

function Game:update()
    -- update entities
    if self.hintCrank then
        pd.ui.crankIndicator:draw()
    end

    if not FilePlayer.isPlaying() then
        FilePlayer.play(assets.music.game)
    end

    if SpriteRescueCounter.getInstance():isAllSpritesRescued() then
        spriteLevelCompleteText:add()
        spriteLevelCompleteHintText:add()
    end

    spriteLevelCompleteText:setVisible(blinkerLevelComplete.on)
    spriteLevelCompleteHintText:setVisible(blinkerLevelComplete.on)
end

function Game:leave(next, ...)
    -- Clear sprites in level

    gfx.sprite.removeAll()

    --

    if next.super.className == "Start" or next.super.className == "Menu" then
        -- Remove end timer

        if timerEndSceneTransition then
            self.timerEndSceneTransition:remove()
            self.timerEndSceneTransition = nil
        end

        -- Clear player data

        Player.destroy()

        -- Clear checkpoints

        Checkpoint.clearAll()

        -- Clear rescued sprites

        SpriteRescueCounter.destroy()

        -- Remove system/PD menu items

        systemMenu:removeAllMenuItems()

        -- Remove currentGame reference from manager
        sceneManager.scenes.currentGame = nil

        -- Stop the music!

        FilePlayer.stop()
    end
end

-- Checkpoint interface

function Game:handleCheckpointRevert(state)
    if currentLevelName ~= state.levelName then
        sceneManager:enter(sceneManager.scenes.currentGame,
            { level = { name = state.levelName }, isCheckpointRevert = true })
    end
end

-- Event-based methods

function Game:levelComplete(data)
    local direction = data.direction
    local coordinates = data.coordinates

    -- Load next level

    local nextLevel, nextLevelBounds = LDtk.getNeighborLevelForPos(currentLevelName, direction, coordinates)

    sceneManager:enter(sceneManager.scenes.currentGame,
        { direction = direction, level = { name = nextLevel, bounds = nextLevelBounds } })
end

function Game:botRescued(bot, botNumber)
    local spriteRescueCounter = SpriteRescueCounter.getInstance()
    spriteRescueCounter:setSpriteRescued(botNumber)

    if spriteRescueCounter:isAllSpritesRescued() then
        spriteLevelCompleteText:add()
        spriteLevelCompleteHintText:add()

        blinkerLevelComplete:startLoop()

        -- Set level complete in data

        MemoryCard.setLevelComplete()
    end
end

function Game:updateBlueprints()
    local abilityPanel = AbilityPanel.getInstance()
    abilityPanel:updateBlueprints()
end

function Game:checkpointIncrement()
    Checkpoint.increment()
end

function Game:checkpointRevert()
    if not SpriteRescueCounter.getInstance():isAllSpritesRescued() then
        -- Revert checkpoint
        Checkpoint.goToPrevious()
    elseif not self.timerEndSceneTransition then
        -- If all bots have been rescued, then finish the level.

        Player.getInstance():setWarpLoopAnimation(true)

        self.timerEndSceneTransition = playdate.timer.performAfterDelay(3000, function()
            sceneManager:enter(sceneManager.scenes.menu)
        end)
    end
end

function Game:hideOrShowGui(shouldHide)
    local abilityPanel = AbilityPanel.getInstance()

    if shouldHide then
        abilityPanel:hide()
    else
        abilityPanel:show()
    end
end
