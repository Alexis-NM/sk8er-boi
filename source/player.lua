--- player.lua
--- Module qui gère le skateur : chargement des variantes d'image (droite, gauche, haut, bas),
--- position, update, et conservation de l'orientation quand il est à l'arrêt.

import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx <const> = playdate.graphics
local pd  <const> = playdate

---@class Player
---@field imageRight _Image?     # l’image “skater” qui regarde vers la droite
---@field imageUp _Image?        # l’image “skater_up” qui regarde vers le haut
---@field imageDown _Image?      # l’image “skater_down” qui regarde vers le bas
---@field sprite _Sprite?        # l’objet sprite associé
---@field x number?              # coordonnée X du centre
---@field y number?              # coordonnée Y du centre
---@field width number?          # largeur du sprite (généralement 32)
---@field height number?         # hauteur du sprite (généralement 32)
---@field speed number           # vitesse de déplacement (pixels/frame)
---@field facingLeft boolean     # si on regarde latéralement vers la gauche
---@field lastDirection string   # "right", "left", "up" ou "down", dernière direction traversée
local Player = {}

--- Initialise le joueur : charge toutes les variantes d’image, crée le sprite, le centre à l’écran.
function Player:init()
    -- Charger l’image latérale (vers la droite par défaut) :
    ---@type _Image?
    self.imageRight = gfx.image.new("assets/sprites/skater")
    if not self.imageRight then
        error("player:init() → impossible de charger 'assets/sprites/skater.png'")
    end

    -- Charger l’image « vers le haut » :
    ---@type _Image?
    self.imageUp = gfx.image.new("assets/sprites/skater_up")
    if not self.imageUp then
        error("player:init() → impossible de charger 'assets/sprites/skater_up.png'")
    end

    -- Charger l’image « vers le bas » :
    ---@type _Image?
    self.imageDown = gfx.image.new("assets/sprites/skater_down")
    if not self.imageDown then
        error("player:init() → impossible de charger 'assets/sprites/skater_down.png'")
    end

    -- Créer le sprite en prenant par défaut l’image de droite :
    ---@type _Sprite?
    self.sprite = gfx.sprite.new(self.imageRight)
    if not self.sprite then
        error("player:init() → impossible de créer le sprite à partir de l’image")
    end

    -- Position initiale au centre de l’écran Playdate (400×240 → 200, 120)
    self.x, self.y = 200, 120

    -- Taille du sprite (ici, 32×32)
    self.width, self.height = self.imageRight:getSize()

    -- Vitesse de déplacement (pixels par frame)
    self.speed = 2

    -- Orientation latérale de base : on regarde vers la droite
    self.facingLeft = false
    self.sprite:setImage(self.imageRight)
    self.sprite:setImageFlip(playdate.graphics.kImageUnflipped, false)

    -- On commence par défaut avec “lastDirection” = "right"  
    -- (pour qu’à l’arrêt au démarrage, on reste en vue latérale droite)
    self.lastDirection = "right"

    -- Positionner et activer le sprite
    self.sprite:moveTo(self.x, self.y)
    self.sprite:add()
end

--- Met à jour l’état du joueur :
--- - Détermine la direction (haut, bas, ou latérale)
--- - Change l’image du sprite en fonction
--- - Enregistre lastDirection pour la conserver à l’arrêt
--- - Gère le flip horizontal pour la vue latérale
--- - Déplace le sprite sur l’écran
function Player:update()
    if not self.sprite then
        return
    end

    -- 1) Lecture des touches (dx, dy)
    local dx, dy = 0, 0
    local pressingLeft  = pd.buttonIsPressed(pd.kButtonLeft)
    local pressingRight = pd.buttonIsPressed(pd.kButtonRight)
    local pressingUp    = pd.buttonIsPressed(pd.kButtonUp)
    local pressingDown  = pd.buttonIsPressed(pd.kButtonDown)

    if pressingLeft then
        dx = -self.speed
    elseif pressingRight then
        dx = self.speed
    end

    if pressingUp then
        dy = -self.speed
    elseif pressingDown then
        dy = self.speed
    end

    -- 2) Choix de la direction courante et enregistrement de lastDirection
    --    On donne la priorité aux flèches haut/bas sur la vue latérale.
    if pressingDown then
        -- On va vers le bas
        self.lastDirection = "down"
    elseif pressingUp then
        -- On va vers le haut
        self.lastDirection = "up"
    elseif dx < 0 then
        -- On va vers la gauche latérale
        self.lastDirection = "left"
    elseif dx > 0 then
        -- On va vers la droite latérale
        self.lastDirection = "right"
    end
    -- Si aucune touche n’est enfoncée, lastDirection reste ce qu’il était.

    -- 3) En fonction de lastDirection, on choisit l’image à afficher
    if self.lastDirection == "down" then
        self.sprite:setImage(self.imageDown)
        self.sprite:setImageFlip(playdate.graphics.kImageUnflipped, false)

    elseif self.lastDirection == "up" then
        self.sprite:setImage(self.imageUp)
        self.sprite:setImageFlip(playdate.graphics.kImageUnflipped, false)

    elseif self.lastDirection == "left" then
        -- Vue latérale, tournée vers la gauche
        self.sprite:setImage(self.imageRight)
        if not self.facingLeft then
            self.facingLeft = true
        end
        self.sprite:setImageFlip(playdate.graphics.kImageFlippedX, false)

    elseif self.lastDirection == "right" then
        -- Vue latérale, tournée vers la droite
        self.sprite:setImage(self.imageRight)
        if self.facingLeft then
            self.facingLeft = false
        end
        self.sprite:setImageFlip(playdate.graphics.kImageUnflipped, false)
    end

    -- 4) Mise à jour de la position
    self.x = (self.x or 0) + dx
    self.y = (self.y or 0) + dy

    -- 5) Contrainte aux limites de l’écran (pour que le joueur ne sorte pas)
    local halfW = (self.width or 0) / 2
    local halfH = (self.height or 0) / 2
    if self.x < halfW then
        self.x = halfW
    elseif self.x > (400 - halfW) then
        self.x = 400 - halfW
    end
    if self.y < halfH then
        self.y = halfH
    elseif self.y > (240 - halfH) then
        self.y = 240 - halfH
    end

    -- 6) Déplacer le sprite à sa nouvelle position
    self.sprite:moveTo(self.x, self.y)
end

return Player