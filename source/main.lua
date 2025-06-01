--- main.lua
--- Boucle principale qui charge le Player et invoque update/draw chaque frame.

import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/ui"
local gfx <const> = playdate.graphics

---@type Player?
local Player = import("player")
---@type Player?
local player = Player

-- Vérifier avant d’appeler init()
if not player or type(player.init) ~= "function" then
    error("Impossible d'importer le module Player ou méthode init() manquante")
end

player:init()

function playdate.update()
    gfx.clear()

    if player and type(player.update) == "function" then
        player:update()
    end

    gfx.sprite.update()
end