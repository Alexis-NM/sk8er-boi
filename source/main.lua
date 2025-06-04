import "CoreLibs/graphics"
import "CoreLibs/sprites"
local pd  <const> = playdate
local gfx <const> = pd.graphics

local Splash = import("splash")
Splash:init("assets/images/splash", 45.0)

local player = import("player")
player:init()

local MusicManager = import("music_manager")
local musicMgr = MusicManager
local musicStarted = false


function pd.update()
    gfx.clear()

    if not Splash:update() then
        return
    end

    if not musicStarted then
        musicMgr:init("assets/sounds/music", "assets/sounds/music_2")
        musicStarted = true
    end

    player:update()
    gfx.sprite.update()
end
