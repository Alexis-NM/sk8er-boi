-- player.lua
import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx <const> = playdate.graphics
local pd  <const> = playdate

local Player = {}

function Player:init()
    -- 1) Chargement des images
    self.imageNeutral   = gfx.image.new("assets/sprites/skater")          or error("failed to load skater.png")
    self.imageRun2      = gfx.image.new("assets/sprites/skater_run_2")     or error("failed to load skater_run_2.png")
    self.imageJump1     = gfx.image.new("assets/sprites/skater_jump")      or error("failed to load skater_jump.png")
    self.imageJump2     = gfx.image.new("assets/sprites/skater_jump_2")    or error("failed to load skater_jump_2.png")
    self.imageJump3     = gfx.image.new("assets/sprites/skater_jump_3")    or error("failed to load skater_jump_3.png")
    self.imageDown      = gfx.image.new("assets/sprites/skater_down")      or error("failed to load skater_down.png")
    self.imageUp        = gfx.image.new("assets/sprites/skater_up")        or error("failed to load skater_up.png")

    -- 2) Tableau de l’animation de saut + offsets Y
    self.jumpImages = {
        self.imageRun2,     -- frame 1 : run2
        self.imageJump1,    -- frame 2 : jump1
        self.imageJump2,    -- frame 3 : jump2 (point haut)
        self.imageJump3,    -- frame 4 : jump3
        self.imageNeutral   -- frame 5 : retour au sol
    }
    self.jumpYOffsets = {
        0,    -- run2
        -10,    -- jump1
        -30,  -- jump2 (on remonte de 10px)
        -10,   -- jump3
        0     -- neutral
    }

    -- 3) Création du sprite
    self.sprite = gfx.sprite.new(self.imageNeutral)
    self.x, self.y = 200, 120
    self.width, self.height = self.imageNeutral:getSize()
    self.speed = 2
    self.facingLeft = false
    self.lastDirection = "right"
    self.baseY = self.y  -- Y de référence quand on n'est pas en saut

    self.sprite:setImage(self.imageNeutral)
    self.sprite:setImageFlip(gfx.kImageUnflipped, false)
    self.sprite:moveTo(self.x, self.y)
    self.sprite:add()

    -- 4) Variables pour le saut
    self.isJumping = false
    self.jumpFrameIndex = 0
    self.framesPerJumpFrame = 5  -- ← on passe de 3 à 5 pour ralentir encore
    self.jumpTimer = 0
end

function Player:update()
    if not self.sprite then return end

    -- === Si on est en plein saut ===
    if self.isJumping then
        -- 1) Incrémenter le timer
        self.jumpTimer = self.jumpTimer + 1

        -- 2) Quand le timer atteint framesPerJumpFrame, on change de frame
        if self.jumpTimer >= self.framesPerJumpFrame then
            self.jumpTimer = 0
            self.jumpFrameIndex = self.jumpFrameIndex + 1
        end

        -- 3) Si on a fini la dernière frame, on revient à l’état normal
        if self.jumpFrameIndex > #self.jumpImages then
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
            -- 4) Sinon, on affiche la frame courante avec son offset Y
            local img = self.jumpImages[self.jumpFrameIndex]
            local yOffset = self.jumpYOffsets[self.jumpFrameIndex]

            self.sprite:setImage(img)
            -- Conserver le flip horizontal si nécessaire (sur frame 1 ou frame finale)
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

            -- Ajuster la position Y selon l’offset
            self.y = self.baseY + yOffset
            self.sprite:moveTo(self.x, self.y)
        end

        return
    end

    -- === Sinon, on gère le mouvement normal ===
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

    -- Mise à jour du « lastDirection »
    if     dy > 0 then 
        self.lastDirection = "down"
    elseif dy < 0 then 
        self.lastDirection = "up"
    elseif dx < 0 then 
        self.lastDirection = "left"
    elseif dx > 0 then 
        self.lastDirection = "right"
    end

    -- On change l’image selon la direction
    if     self.lastDirection == "down" then
        self.sprite:setImage(self.imageDown)
        self.sprite:setImageFlip(gfx.kImageUnflipped, false)
    elseif self.lastDirection == "up" then
        self.sprite:setImage(self.imageUp)
        self.sprite:setImageFlip(gfx.kImageUnflipped, false)
    else
        self.sprite:setImage(self.imageNeutral)
        if self.lastDirection == "left" then
            self.facingLeft = true
            self.sprite:setImageFlip(gfx.kImageFlippedX, false)
        else
            self.facingLeft = false
            self.sprite:setImageFlip(gfx.kImageUnflipped, false)
        end
    end

    -- Mise à jour des coordonnées (bornées à l’écran)
    self.x = math.min(math.max((self.x or 0) + dx, self.width/2),  400 - self.width/2)
    self.y = math.min(math.max((self.y or 0) + dy, self.height/2), 240 - self.height/2)
    self.baseY = self.y  -- on met à jour baseY au cas où on relance un saut

    -- Détection de l’appui sur A pour démarrer le jump
    if pd.buttonJustPressed(pd.kButtonA) then
        self.isJumping = true
        self.jumpFrameIndex = 1   -- première frame (run2)
        self.jumpTimer = 0        -- reset du timer
    end

    -- On déplace le sprite
    self.sprite:moveTo(self.x, self.y)
end

return Player