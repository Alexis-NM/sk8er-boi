import "CoreLibs/graphics"
import "CoreLibs/sprites"
local pd  <const> = playdate
local gfx <const> = pd.graphics

local Splash = import("splash")
Splash:init("assets/images/splash", 45.0)

local Level1       = import("level_1")
local Player       = import("player_level_1")
local MusicManager = import("music_manager")

local musicStarted = false

-- Initialize level and player before the first frame
Level1.init()
Player:init()

-- Mark the level as started immediately
Level1.isLevelStarted = true

function pd.update()
    gfx.clear()

    -- Display the splash screen at launch
    if Splash and not Splash:update() then
        return
    end

    -- Start background music once
    if not musicStarted then
        MusicManager:init("assets/sounds/music", "assets/sounds/music_2")
        musicStarted = true
    end

    -- Update the player (handles jumping on button A)
    Player:update(Level1.isLevelStarted)

    -- Scroll the background when the level is active
    if Level1.isLevelStarted then
        if pd.buttonIsPressed(pd.kButtonRight) then
            Level1.updateScroll()
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            Level1.scrollX = (Level1.scrollX - Level1.bgScrollSpeed) % Level1.bgWidth
        end
    end

    -- Draw all sprites and background
    gfx.sprite.update()
end
