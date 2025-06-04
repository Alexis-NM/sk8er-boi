-- player.lua
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx <const> = playdate.graphics
local pd  <const> = playdate

local Player = {}

function Player:init()
    -- 1) Chargement des images
    self.imageNeutral   = gfx.image.new("assets/sprites/skater")            or error("failed to load skater.png")
    self.imageRun1      = gfx.image.new("assets/sprites/skater_run")        or error("failed to load skater_run.png")
    self.imageRun2      = gfx.image.new("assets/sprites/skater_run_2")      or error("failed to load skater_run_2.png")
    self.imageJump1     = gfx.image.new("assets/sprites/skater_jump")       or error("failed to load skater_jump.png")
    self.imageJump2     = gfx.image.new("assets/sprites/skater_jump_2")     or error("failed to load skater_jump_2.png")
    self.imageJump3     = gfx.image.new("assets/sprites/skater_jump_3")     or error("failed to load skater_jump_3.png")
    self.imageDown      = gfx.image.new("assets/sprites/skater_down")       or error("failed to load skater_down.png")
    self.imageUp        = gfx.image.new("assets/sprites/skater_up")         or error("failed to load skater_up.png")

    -- 2) Tableau “template” de l’animation de saut (on va construire les offsets dynamiquement)
    self.jumpImages = {
        self.imageRun2,     -- frame 1 : run2
        self.imageJump1,    -- frame 2 : jump1
        self.imageJump2,    -- frame 3 : jump2 (point haut)
        self.imageJump3,    -- frame 4 : jump3 (redescente partielle)
        self.imageNeutral   -- frame 5 : retour au sol
    }

    -- Pour l’instant, on laisse une valeur par défaut (sera recalculée à chaque saut)
    self.jumpYOffsets = { 0, -30, -60, -30, 0 }

    -- 3) Tableau de l’animation de course (poussée)
    self.runImages = {
        self.imageRun1,    -- frame 1 : skater_run
        self.imageRun2     -- frame 2 : skater_run_2
    }

    -- 4) Sprite de base
    self.sprite = gfx.sprite.new(self.imageNeutral)
    self.x, self.y = 200, 120
    self.width, self.height = self.imageNeutral:getSize()
    self.speed = 2
    self.facingLeft = false
    self.lastDirection = "right"
    self.baseY = self.y  -- Hauteur « au sol » quand on n’est pas en saut

    self.sprite:setImage(self.imageNeutral)
    self.sprite:setImageFlip(gfx.kImageUnflipped, false)
    self.sprite:moveTo(self.x, self.y)
    self.sprite:add()

    -- 5) Variables pour le saut
    self.isJumping = false
    self.jumpFrameIndex = 0
    self.framesPerJumpFrame = 5   -- ajustable pour la vitesse de l’animation de saut
    self.jumpTimer = 0

    -- 6) Variables pour la course (poussée)
    self.isRunning = false
    self.runFrameIndex = 1        -- on démarre à 1, jamais à 0
    self.framesPerRunFrame = 8    -- ajustable : plus c’est grand, plus l’animation de course est lente
    self.runTimer = 0

    -- 7) Variables pour la détection de la durée d’appui sur A
    self.isHoldingJump = false
    self.holdTimer = 0          -- compte combien de boucles update() A reste appuyé
    self.maxHoldTime = 30       -- on plafonne la “charge” après environ 30 update() (~0.6 s si 50fps)
    self.minJumpPeak = 5       -- hauteur minimale du saut (en pixels)
    self.maxJumpPeak = 80       -- hauteur maximale du saut (en pixels)
end

function Player:update()
    if not self.sprite then return end

    -- === 1) Gérer la détection du bouton A pour mesurer la durée d’appui ===
    if pd.buttonIsPressed(pd.kButtonA) then
        if not self.isHoldingJump and not self.isJumping then
            -- on vient de commencer à appuyer (ni on ne sautait déjà, ni on ne mesurait)
            self.isHoldingJump = true
            self.holdTimer = 0
        elseif self.isHoldingJump then
            -- on continue d’appuyer => incrémenter holdTimer (capé à maxHoldTime)
            if self.holdTimer < self.maxHoldTime then
                self.holdTimer = self.holdTimer + 1
            end
        end
    elseif self.isHoldingJump and not self.isJumping then
        -- on vient de relâcher A ⇒ on calcule la “peak” du saut proportionnelle à holdTimer
        self.isHoldingJump = false

        -- Fraction de charge ∈ [0,1]
        local frac = self.holdTimer / self.maxHoldTime
        if frac > 1 then frac = 1 end
        -- Calcule la hauteur de saut entre minJumpPeak et maxJumpPeak
        local peak = self.minJumpPeak + (self.maxJumpPeak - self.minJumpPeak) * frac

        -- Construire dynamiquement les offsets Y pour l’animation de 5 frames
        -- On va faire un petit arc simple : 
        --   frame 1 = run2 au sol (offset 0),
        --   frame 2 = montée partielle (peak * 0.5),
        --   frame 3 = apogée (peak),
        --   frame 4 = redescente partielle (peak * 0.5),
        --   frame 5 = retour au sol (0).
        self.jumpYOffsets = {
            0,
            -math.floor(peak * 0.5),
            -math.floor(peak),
            -math.floor(peak * 0.5),
            0
        }

        -- Lancer l’animation de saut
        self.isJumping = true
        self.jumpFrameIndex = 1   -- première frame (run2)
        self.jumpTimer = 0
    end

    -- === 2) Si on est déjà en plein saut, on gère l’animation de saut ===
    if self.isJumping then
        -- Incrémenter le timer de saut
        self.jumpTimer = self.jumpTimer + 1
        if self.jumpTimer >= self.framesPerJumpFrame then
            self.jumpTimer = 0
            self.jumpFrameIndex = self.jumpFrameIndex + 1
        end

        -- Si on a fini la dernière frame, on revient à l’état normal
        if self.jumpFrameIndex > #self.jumpImages then
            self.isJumping = false
            self.jumpFrameIndex = 0
            -- Remettre l’image neutre (avec flip si nécessaire)
            if self.facingLeft then
                self.sprite:setImage(self.imageNeutral)
                self.sprite:setImageFlip(gfx.kImageFlippedX, false)
            else
                self.sprite:setImage(self.imageNeutral)
                self.sprite:setImageFlip(gfx.kImageUnflipped, false)
            end
            -- Revenir à la hauteur de base
            self.y = self.baseY
            self.sprite:moveTo(self.x, self.y)
        else
            -- Afficher la frame de saut courante + offset vertical calculé
            local img     = self.jumpImages[self.jumpFrameIndex]
            local yOffset = self.jumpYOffsets[self.jumpFrameIndex]
            self.sprite:setImage(img)

            -- Conserver le flip horizontal si nécessaire (frame 1 ou frame finale)
            if self.jumpFrameIndex == 1 or self.jumpFrameIndex == #self.jumpImages then
                if self.facingLeft then
                    self.sprite:setImageFlip(gfx.kImageFlippedX, false)
                else
                    self.sprite:setImageFlip(gfx.kImageUnflipped, false)
                end
            else
                if self.facingLeft then
                    self.sprite:setImageFlip(gfx.kImageFlippedX, false)
                else
                    self.sprite:setImageFlip(gfx.kImageUnflipped, false)
                end
            end

            -- Ajuster la position Y selon yOffset
            self.y = self.baseY + yOffset
            self.sprite:moveTo(self.x, self.y)
        end

        -- Tant qu’on saute, on ne gère ni la course ni le déplacement normal
        return
    end

    -- === 3) Calcul du dx, dy selon les flèches (si on ne saute pas) ===
    local dx, dy = 0, 0
    if pd.buttonIsPressed(pd.kButtonLeft) then 
        dx = -self.speed
    elseif pd.buttonIsPressed(pd.kButtonRight) then 
        dx = self.speed 
    end
    if pd.buttonIsPressed(pd.kButtonUp) then 
        dy = -self.speed
    elseif pd.buttonIsPressed(pd.kButtonDown) then 
        dy = self.speed 
    end

    -- Mise à jour de la “lastDirection” pour choisir l’image appropriée
    if     dy > 0 then 
        self.lastDirection = "down"
    elseif dy < 0 then 
        self.lastDirection = "up"
    elseif dx < 0 then 
        self.lastDirection = "left"
    elseif dx > 0 then 
        self.lastDirection = "right"
    end

    -- === 4) Mise à jour des coordonnées AVANT de changer l’image ===
    self.x = math.min(math.max((self.x or 0) + dx, self.width/2),  400 - self.width/2)
    self.y = math.min(math.max((self.y or 0) + dy, self.height/2), 240 - self.height/2)
    self.baseY = self.y  -- utile si on va démarrer un saut ensuite

    -- === 5) Animation de course (si dx ≠ 0) ===
    if dx ~= 0 then
        self.isRunning = true

        -- Incrémenter le timer de course
        self.runTimer = self.runTimer + 1
        if self.runTimer >= self.framesPerRunFrame then
            self.runTimer = 0
            self.runFrameIndex = self.runFrameIndex + 1
            if self.runFrameIndex > #self.runImages then
                self.runFrameIndex = 1
            end
        end

        -- Choisir l’image de course + appliquer le flip
        local imgRun = self.runImages[self.runFrameIndex]
        self.sprite:setImage(imgRun)
        if self.lastDirection == "left" then
            self.facingLeft = true
            self.sprite:setImageFlip(gfx.kImageFlippedX, false)
        else
            self.facingLeft = false
            self.sprite:setImageFlip(gfx.kImageUnflipped, false)
        end

        -- Garder la même hauteur de sol (pas de saut ici)
        self.y = self.baseY
        self.sprite:moveTo(self.x, self.y)
    else
        -- === 6) Si dx == 0, on n’avance pas ⇒ on arrête l’animation de course ===
        if self.isRunning then
            self.isRunning = false
            self.runFrameIndex = 1    -- pour repartir proprement si on recommence à courir
            self.runTimer = 0
        end

        -- Afficher l’image “immobile” selon lastDirection
        if     self.lastDirection == "down" then
            self.sprite:setImage(self.imageDown)
        elseif self.lastDirection == "up" then
            self.sprite:setImage(self.imageUp)
        else
            -- lastDirection est “left” ou “right”, mais dx = 0 ⇒ image neutre
            self.sprite:setImage(self.imageNeutral)
        end
        if self.lastDirection == "left" then
            self.facingLeft = true
            self.sprite:setImageFlip(gfx.kImageFlippedX, false)
        else
            self.facingLeft = false
            self.sprite:setImageFlip(gfx.kImageUnflipped, false)
        end

        self.y = self.baseY
        self.sprite:moveTo(self.x, self.y)
    end
end

return Player