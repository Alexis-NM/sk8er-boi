import "CoreLibs/graphics"
import "CoreLibs/sprites"
local pd  <const> = playdate
local gfx <const> = pd.graphics

local Level1 = {}

function Level1.init()
    -- 1) Chargement du background
    Level1.bgImage = gfx.image.new("assets/images/background")
    if not Level1.bgImage then
        error("Échec du chargement de assets/images/background.png")
    end

    Level1.bgWidth, Level1.bgHeight = Level1.bgImage:getSize()

    -- 2) Vitesse de défilement en pixels par frame
    Level1.bgScrollSpeed = 2

    -- 3) Position de défilement initiale
    Level1.scrollX = 0

    -- 4) Indicateur si le niveau a démarré (sera mis à true par main.lua)
    Level1.isLevelStarted = false

    -- 5) Hauteur du sol (utile éventuellement si on rajoute obstacles plus tard)
    Level1.groundY = 200

    -- 6) Callback pour dessiner le fond AVANT les sprites
    gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h)
        -- On dessine deux copies côte à côte, décalées de scrollX
        Level1.bgImage:draw(-Level1.scrollX, 0)
        Level1.bgImage:draw(-Level1.scrollX + Level1.bgWidth, 0)
    end)
end

-- Cette fonction est appelée par main.lua (une fois par frame) si isLevelStarted == true
function Level1.updateScroll()
    -- Faire avancer le scroll (simple modulo pour boucle infinie)
    Level1.scrollX = (Level1.scrollX + Level1.bgScrollSpeed) % Level1.bgWidth
end

return Level1