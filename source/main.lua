import "CoreLibs/graphics"
import "CoreLibs/sprites"
local pd  <const> = playdate
local gfx <const> = pd.graphics

-- (1) Splash optionnel
local Splash = import("splash")
Splash:init("assets/images/splash", 45.0)

-- (2) Modules
local Level1       = import("level_1")
local Player       = import("player_level_1")
local MusicManager = import("music_manager")

local musicStarted = false

-- (3) Initialisation avant la première update
Level1.init()           -- charge uniquement le background
Player:init()           -- crée le sprite et les variables du skater

-- → On force tout de suite le niveau comme “démarré”,
--   pour que la condition de scroll soit vraie dès le début.
Level1.isLevelStarted = true

function pd.update()
    gfx.clear()

    -- → Splash au début
    if Splash and not Splash:update() then
        return
    end

    -- → Démarrage d’une seule passe de la musique
    if not musicStarted then
        MusicManager:init("assets/sounds/music", "assets/sounds/music_2")
        musicStarted = true
    end

    -- → Mise à jour du joueur (il gère toujours le saut si on appuie sur A)
    Player:update(Level1.isLevelStarted)

    -- → On retire la logique “Player.isCharged devient true”,
    --   puisque le niveau est déjà marqué comme démarré ci-dessus.

    -- → Si le “niveau” est lancé (toujours vrai dès le début),
    --   on scrolle quand on appuie sur Droite/Gauche
    if Level1.isLevelStarted then
        if pd.buttonIsPressed(pd.kButtonRight) then
            Level1.updateScroll()
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            Level1.scrollX = (Level1.scrollX - Level1.bgScrollSpeed) % Level1.bgWidth
        end
    end

    -- → Enfin, on dessine tout (callback de fond + sprites)
    gfx.sprite.update()
end