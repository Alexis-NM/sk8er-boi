import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx <const> = playdate.graphics
local pd  <const> = playdate

local Player = {}

function Player:init()
    -- 1) Chargement des images du skater
    self.imageNeutral   = gfx.image.new("assets/sprites/skater")         or error("failed to load skater.png")
    self.imageRun1      = gfx.image.new("assets/sprites/skater_run")     or error("failed to load skater_run.png")
    self.imageRun2      = gfx.image.new("assets/sprites/skater_run_2")   or error("failed to load skater_run_2.png")
    self.imageJump1     = gfx.image.new("assets/sprites/skater_jump")    or error("failed to load skater_jump.png")
    self.imageJump2     = gfx.image.new("assets/sprites/skater_jump_2")  or error("failed to load skater_jump_2.png")
    self.imageJump3     = gfx.image.new("assets/sprites/skater_jump_3")  or error("failed to load skater_jump_3.png")
    self.imageDown      = gfx.image.new("assets/sprites/skater_down")    or error("failed to load skater_down.png")
    self.imageUp        = gfx.image.new("assets/sprites/skater_up")      or error("failed to load skater_up.png")

    -- 2) Animation de saut (5 frames)
    self.jumpImages = {
        self.imageRun2,     -- frame 1 : run2 (avant décoller)
        self.imageJump1,    -- frame 2 : jump1
        self.imageJump2,    -- frame 3 : jump2 (apogée)
        self.imageJump3,    -- frame 4 : jump3 (redescente partielle)
        self.imageNeutral   -- frame 5 : retour au sol
    }
    self.jumpYOffsets = { 0, -30, -60, -30, 0 }

    -- 3) Animation de course (sur place)
    self.runImages = {
        self.imageRun1,    -- frame 1 : skater_run
        self.imageRun2     -- frame 2 : skater_run_2
    }

    -- 4) Création du sprite et position initiale (x=80, y=220-centre du sprite)
    local baseX = 80
    local _, spriteH = self.imageNeutral:getSize()
    local baseY = 220 - (spriteH / 2)

    self.sprite = gfx.sprite.new(self.imageNeutral)
    self.x, self.y = baseX, baseY
    self.width, self.height = self.imageNeutral:getSize()
    self.facingLeft = false
    self.baseY = self.y   -- y « au sol » pour le saut

    -- 4.1) Variables pour la course libre (après lancement du niveau)
    self.speed = 2
    self.lastDirection = "right"

    -- 4.2) Limite haute pour que le skater ne remonte pas trop
    -- Ici, self.minY correspond au centre du sprite : il ne pourra pas passer au-dessus de cette valeur.
    -- Ajustez 60 à la hauteur minimale que vous souhaitez.
    self.minY = 150

    self.sprite:setImage(self.imageNeutral)
    self.sprite:setImageFlip(gfx.kImageUnflipped, false)
    self.sprite:moveTo(self.x, self.y)
    self.sprite:add()

    -- 5) Variables pour le saut
    self.isJumping        = false
    self.jumpFrameIndex   = 0
    self.framesPerJumpFrame = 5
    self.jumpTimer        = 0

    -- 6) Variables pour la course-sur-place (prise d’élan)
    self.isRunning        = false
    self.runFrameIndex    = 1
    self.framesPerRunFrame = 8
    self.runTimer         = 0

    -- 7) Variables pour mesurer la durée d’appui sur A (charge du saut)
    self.isHoldingJump    = false
    self.holdTimer        = 0
    self.maxHoldTime      = 30
    self.minJumpPeak      = 5
    self.maxJumpPeak      = 80

    -- 8) Variables pour la charge avant départ de niveau
    self.chargeTimer      = 0
    self.requiredCharge   = 30  -- ≈0,6 s à 50 FPS
    self.isCharged        = false
end

-- update(isLevelStarted) : on passe isLevelStarted depuis main.lua
function Player:update(isLevelStarted)
    if not self.sprite then return end

    -------------------------------------------------------------------
    -- A) GESTION DU SAUT (prioritaire, même si niveau pas lancé) -----
    -------------------------------------------------------------------

    -- 1) Détection de l’appui / maintien sur A pour mesurer la charge
    if pd.buttonIsPressed(pd.kButtonA) then
        if not self.isHoldingJump and not self.isJumping then
            self.isHoldingJump = true
            self.holdTimer = 0
        elseif self.isHoldingJump then
            if self.holdTimer < self.maxHoldTime then
                self.holdTimer = self.holdTimer + 1
            end
        end
    elseif self.isHoldingJump and not self.isJumping then
        self.isHoldingJump = false
        local frac = self.holdTimer / self.maxHoldTime
        if frac > 1 then frac = 1 end
        local peak = self.minJumpPeak + (self.maxJumpPeak - self.minJumpPeak) * frac
        self.jumpYOffsets = {
            0,
            -math.floor(peak * 0.5),
            -math.floor(peak),
            -math.floor(peak * 0.5),
            0
        }
        self.isJumping = true
        self.jumpFrameIndex = 1
        self.jumpTimer = 0
    end

    -- 2) Si en plein saut, dérouler l’animation
    if self.isJumping then
        self.jumpTimer = self.jumpTimer + 1
        if self.jumpTimer >= self.framesPerJumpFrame then
            self.jumpTimer = 0
            self.jumpFrameIndex = self.jumpFrameIndex + 1
        end
        if self.jumpFrameIndex > #self.jumpImages then
            -- Fin du saut
            self.isJumping = false
            self.jumpFrameIndex = 0
            if self.facingLeft then
                self.sprite:setImage(self.imageNeutral)
                self.sprite:setImageFlip(gfx.kImageFlippedX, false)
            else
                self.sprite:setImage(self.imageNeutral)
                self.sprite:setImageFlip(gfx.kImageUnflipped, false)
            end
            self.y = self.baseY
            self.sprite:moveTo(self.x, self.y)
        else
            -- Afficher la frame courante + offset vertical
            local img     = self.jumpImages[self.jumpFrameIndex]
            local yOffset = self.jumpYOffsets[self.jumpFrameIndex]
            self.sprite:setImage(img)
            if self.facingLeft then
                self.sprite:setImageFlip(gfx.kImageFlippedX, false)
            else
                self.sprite:setImageFlip(gfx.kImageUnflipped, false)
            end
            self.y = self.baseY + yOffset
            self.sprite:moveTo(self.x, self.y)
        end
        return
    end

    -------------------------------------------------------------------
    -- B) NIVEAU PAS ENCORE LANCÉ → prise d’élan en animant la course ----
    -------------------------------------------------------------------

    if not isLevelStarted then
        local dx = 0
        if pd.buttonIsPressed(pd.kButtonRight) then
            dx = 1
        elseif pd.buttonIsPressed(pd.kButtonLeft) then
            dx = -1
        end

        if dx ~= 0 then
            self.isRunning = true
            self.runTimer = self.runTimer + 1
            if self.runTimer >= self.framesPerRunFrame then
                self.runTimer = 0
                self.runFrameIndex = self.runFrameIndex + 1
                if self.runFrameIndex > #self.runImages then
                    self.runFrameIndex = 1
                end
            end

            local imgRun = self.runImages[self.runFrameIndex]
            self.sprite:setImage(imgRun)
            if dx < 0 then
                self.facingLeft = true
                self.sprite:setImageFlip(gfx.kImageFlippedX, false)
            else
                self.facingLeft = false
                self.sprite:setImageFlip(gfx.kImageUnflipped, false)
            end

            if self.runFrameIndex == 1 and self.runTimer == 0 then
                self.chargeTimer = self.chargeTimer + 1
                if self.chargeTimer >= self.requiredCharge then
                    self.isCharged = true
                end
            end
        else
            if self.isRunning then
                self.isRunning = false
                self.runFrameIndex = 1
                self.runTimer = 0
            end
            self.sprite:setImage(self.imageNeutral)
            self.sprite:setImageFlip(gfx.kImageUnflipped, false)
        end
        return
    end

    -------------------------------------------------------------------
    -- C) NIVEAU LANCÉ → gérer le déplacement + run animation + saut ----
    -------------------------------------------------------------------

    self.sprite:setImage(self.imageNeutral)

    -- 1) Calcul du dx, dy selon les flèches (si on ne saute pas)
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

    -- 2) Mise à jour de la “lastDirection” pour choisir l’image appropriée en idle
    if     dy > 0 then 
        self.lastDirection = "down"
    elseif dy < 0 then 
        self.lastDirection = "up"
    elseif dx < 0 then 
        self.lastDirection = "left"
    elseif dx > 0 then 
        self.lastDirection = "right"
    end

    -- 3) Mise à jour des coordonnées AVANT de changer l’image
    -- On remplace la borne inférieure (self.height/2) par self.minY pour limiter la zone haute.
    -- Borne basse = self.minY, borne haute = 240 - self.height/2
    self.x = math.min(math.max((self.x or 0) + dx, self.width/2),  400 - self.width/2)
    self.y = math.min(
                math.max((self.y or 0) + dy, self.minY),
                240 - (self.height / 2)
             )
    self.baseY = self.y  -- utile si on va démarrer un saut ensuite

    -- 4) Animation de course (si dx ≠ 0)
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

    -- 5) Si dx == 0, on arrête l’animation de course et on affiche l’image idle
    else
        if self.isRunning then
            self.isRunning = false
            self.runFrameIndex = 1
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