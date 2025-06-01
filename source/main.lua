import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/ui"
local gfx <const> = playdate.graphics

local player = import("player")

if not player or type(player.init) ~= "function" then
    error("Unable to import Player module or missing init() method")
end

player:init()

function playdate.update()
    gfx.clear()
    if type(player.update) == "function" then
        player:update()
    end
    gfx.sprite.update()
end
