import "CoreLibs/graphics"
local pd  <const> = playdate
local gfx <const> = pd.graphics

local Splash = {}

function Splash:init(imagePath, duration)
    self.image      = gfx.image.new(imagePath)
    self.startTime  = pd.getElapsedTime()
    self.duration   = duration or 5.0
    self.finished   = false

    -- Paramètres du cercle/pulsation
    self.baseRadius = 10
    self.pulseAmp   = 0.11
    self.pulseFreq  = 1.1
    self.margin     = 12

    -- Charge l’image « A »
    self.bImage = gfx.image.new("assets/images/button_a")
end
function Splash:update()
    if self.finished then
        return true
    end

    -- 1) Sortir si on appuie sur A
    if pd.buttonJustPressed(pd.kButtonA) then
        self.finished = true
        return true
    end

    -- 2) Sortir si la durée max est atteinte
    local elapsed = pd.getElapsedTime() - self.startTime
    if elapsed >= self.duration then
        self.finished = true
        return true
    end

    -- 3) Dessiner le splash (image principale) au centre
    gfx.clear()
    local imgW, imgH = self.image:getSize()
    self.image:draw(
        (400 - imgW) / 2,
        (240 - imgH) / 2
    )

    -- 4) Calcul du rayon flottant et entier (pulsation)
    local rawScale = 1 + self.pulseAmp * math.sin(elapsed * (2 * math.pi * self.pulseFreq))
    local rFloat   = self.baseRadius * rawScale
    local rInt     = math.floor(rFloat + 0.5)

    -- 5) Position du centre (cx, cy) pour que le contour du cercle touche le coin bas-droit
    local cx = math.floor((400 - self.margin) - rInt + 0.5)
    local cy = math.floor((240 - self.margin) - rInt + 0.5)

    -- 6) DESSINER L’IMAGE AVANT LE CERCLE

    local bW, bH = self.bImage:getSize()

    local desiredDiameter = rInt * 2 * 0.65
    local scale = desiredDiameter / math.max(bW, bH)
    local drawW = bW * scale
    local drawH = bH * scale
    local drawX = cx - drawW / 2
    local drawY = cy-1 - drawH / 2

    -- 6a) On dessine l’image (plus petite qu’avant)
    self.bImage:drawScaled(drawX, drawY, scale)

    -- 7) DESSINER LE CONTOUR DU CERCLE PAR‐DESSUS
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawCircleAtPoint(cx, cy, rInt)

    return false
end

return Splash