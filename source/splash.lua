import "CoreLibs/graphics"
local pd   <const> = playdate
local gfx  <const> = pd.graphics

local Splash = {}

function Splash:init(imagePath, duration)
    -- Load the splash image and start the timer
    self.image     = gfx.image.new(imagePath)
    self.startTime = pd.getElapsedTime()
    self.duration  = duration or 5.0
    self.finished  = false

    -- Configure pulsing circle parameters
    self.baseRadius = 10
    self.pulseAmp   = 0.11
    self.pulseFreq  = 1.1
    self.margin     = 12

    -- Load the A-button icon
    self.bImage = gfx.image.new("assets/images/button_a")
end

function Splash:update()
    if self.finished then
        return true
    end

    -- Exit immediately if A is pressed
    if pd.buttonJustPressed(pd.kButtonA) then
        self.finished = true
        return true
    end

    -- Exit when the allotted time has passed
    local elapsed = pd.getElapsedTime() - self.startTime
    if elapsed >= self.duration then
        self.finished = true
        return true
    end

    -- Clear screen and draw the main splash image in the center
    gfx.clear()
    local imgW, imgH = self.image:getSize()
    self.image:draw(
        (400 - imgW) / 2,
        (240 - imgH) / 2
    )

    -- Compute pulsing circle radius
    local rawScale = 1 + self.pulseAmp * math.sin(elapsed * (2 * math.pi * self.pulseFreq))
    local rFloat   = self.baseRadius * rawScale
    local rInt     = math.floor(rFloat + 0.5)

    -- Position the circle so its edge touches the bottom-right corner
    local cx = math.floor((400 - self.margin) - rInt + 0.5)
    local cy = math.floor((240 - self.margin) - rInt + 0.5)

    -- Draw the A-button icon scaled to fit inside the circle
    local bW, bH = self.bImage:getSize()
    local desiredDiameter = rInt * 2 * 0.65
    local scale = desiredDiameter / math.max(bW, bH)
    local drawW, drawH = bW * scale, bH * scale
    local drawX = cx - drawW / 2
    local drawY = cy - drawH / 2 - 1
    self.bImage:drawScaled(drawX, drawY, scale)

    -- Draw the circle outline on top
    gfx.setColor(gfx.kColorBlack)
    gfx.setLineWidth(2)
    gfx.drawCircleAtPoint(cx, cy, rInt)

    return false
end

return Splash
