import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx <const> = playdate.graphics
local pd  <const> = playdate

local Player = {}

function Player:init()
    -- Load skater images
    self.imageNeutral   = gfx.image.new("assets/sprites/skater")         or error("failed to load skater.png")
    self.imageRun1      = gfx.image.new("assets/sprites/skater_run")     or error("failed to load skater_run.png")
    self.imageRun2      = gfx.image.new("assets/sprites/skater_run_2")   or error("failed to load skater_run_2.png")
    self.imageJump1     = gfx.image.new("assets/sprites/skater_jump")    or error("failed to load skater_jump.png")
    self.imageJump2     = gfx.image.new("assets/sprites/skater_jump_2")  or error("failed to load skater_jump_2.png")
    self.imageJump3     = gfx.image.new("assets/sprites/skater_jump_3")  or error("failed to load skater_jump_3.png")
    self.imageDown      = gfx.image.new("assets/sprites/skater_down")    or error("failed to load skater_down.png")
    self.imageUp        = gfx.image.new("assets/sprites/skater_up")      or error("failed to load skater_up.png")

    -- Setup jump animation frames and offsets
    self.jumpImages    = { self.imageRun2, self.imageJump1, self.imageJump2, self.imageJump3, self.imageNeutral }
    self.jumpYOffsets  = { 0, -30, -60, -30, 0 }

    -- Setup run animation frames
    self.runImages     = { self.imageRun1, self.imageRun2 }

    -- Create the sprite and set its initial position
    local baseX = 80
    local _, spriteH = self.imageNeutral:getSize()
    local baseY = 220 - (spriteH / 2)
    self.sprite   = gfx.sprite.new(self.imageNeutral)
    self.x, self.y = baseX, baseY
    self.width, self.height = self.imageNeutral:getSize()
    self.facingLeft = false
    self.baseY      = self.y
    self.speed      = 2
    self.lastDirection = "right"
    self.minY       = 150

    self.sprite:setImage(self.imageNeutral)
    self.sprite:setImageFlip(gfx.kImageUnflipped, false)
    self.sprite:moveTo(self.x, self.y)
    self.sprite:add()

    -- Jump state
    self.isJumping        = false
    self.jumpFrameIndex   = 0
    self.framesPerJumpFrame = 5
    self.jumpTimer        = 0

    -- Run-charge state before starting level
    self.isRunning        = false
    self.runFrameIndex    = 1
    self.framesPerRunFrame = 8
    self.runTimer         = 0

    -- Variables for holding jump button
    self.isHoldingJump    = false
    self.holdTimer        = 0
    self.maxHoldTime      = 30
    self.minJumpPeak      = 5
    self.maxJumpPeak      = 80

    -- Variables for pre-level charge
    self.chargeTimer      = 0
    self.requiredCharge   = 30
    self.isCharged        = false
end

function Player:update(isLevelStarted)
    if not self.sprite then return end

    -- Handle A button hold for jump charging
    if pd.buttonIsPressed(pd.kButtonA) then
        if not self.isHoldingJump and not self.isJumping then
            self.isHoldingJump = true
            self.holdTimer = 0
        elseif self.isHoldingJump and self.holdTimer < self.maxHoldTime then
            self.holdTimer += 1
        end
    elseif self.isHoldingJump and not self.isJumping then
        self.isHoldingJump = false
        local frac = math.min(self.holdTimer / self.maxHoldTime, 1)
        local peak = self.minJumpPeak + (self.maxJumpPeak - self.minJumpPeak) * frac
        self.jumpYOffsets = {
            0,
            -math.floor(peak * 0.5),
            -math.floor(peak),
            -math.floor(peak * 0.5),
            0
        }
        self.isJumping      = true
        self.jumpFrameIndex = 1
        self.jumpTimer      = 0
    end

    -- Play jump animation if jumping
    if self.isJumping then
        self.jumpTimer += 1
        if self.jumpTimer >= self.framesPerJumpFrame then
            self.jumpTimer = 0
            self.jumpFrameIndex += 1
        end

        if self.jumpFrameIndex > #self.jumpImages then
            -- End of jump
            self.isJumping      = false
            self.jumpFrameIndex = 0
            self.sprite:setImage(self.imageNeutral)
            self.sprite:setImageFlip(
                self.facingLeft and gfx.kImageFlippedX or gfx.kImageUnflipped,
                false
            )
            self.y = self.baseY
            self.sprite:moveTo(self.x, self.y)
        else
            -- Continue jump animation
            local img     = self.jumpImages[self.jumpFrameIndex]
            local yOffset = self.jumpYOffsets[self.jumpFrameIndex]
            self.sprite:setImage(img)
            self.sprite:setImageFlip(
                self.facingLeft and gfx.kImageFlippedX or gfx.kImageUnflipped,
                false
            )
            self.y = self.baseY + yOffset
            self.sprite:moveTo(self.x, self.y)
        end
        return
    end

    -- Pre-level run animation for charging
    if not isLevelStarted then
        local dx = pd.buttonIsPressed(pd.kButtonRight) and 1
                or pd.buttonIsPressed(pd.kButtonLeft)  and -1
                or 0

        if dx ~= 0 then
            self.isRunning = true
            self.runTimer += 1
            if self.runTimer >= self.framesPerRunFrame then
                self.runTimer = 0
                self.runFrameIndex = (self.runFrameIndex % #self.runImages) + 1
            end

            local imgRun = self.runImages[self.runFrameIndex]
            self.sprite:setImage(imgRun)
            self.sprite:setImageFlip(
                dx < 0 and gfx.kImageFlippedX or gfx.kImageUnflipped,
                false
            )

            -- Charge increment on each full cycle
            if self.runFrameIndex == 1 and self.runTimer == 0 then
                self.chargeTimer += 1
                if self.chargeTimer >= self.requiredCharge then
                    self.isCharged = true
                end
            end
        else
            -- Reset to neutral if not running
            if self.isRunning then
                self.isRunning, self.runFrameIndex, self.runTimer = false, 1, 0
            end
            self.sprite:setImage(self.imageNeutral)
            self.sprite:setImageFlip(gfx.kImageUnflipped, false)
        end
        return
    end

    -- Level active: movement & run/idle animation
    self.sprite:setImage(self.imageNeutral)
    local dx, dy = 0, 0

    if pd.buttonIsPressed(pd.kButtonLeft)  then dx = -self.speed
    elseif pd.buttonIsPressed(pd.kButtonRight) then dx = self.speed end
    if pd.buttonIsPressed(pd.kButtonUp)    then dy = -self.speed
    elseif pd.buttonIsPressed(pd.kButtonDown)  then dy = self.speed end

    -- Update lastDirection for idle frame
    if    dy > 0 then self.lastDirection = "down"
    elseif dy < 0 then self.lastDirection = "up"
    elseif dx < 0 then self.lastDirection = "left"
    elseif dx > 0 then self.lastDirection = "right" end

    -- Clamp position to screen bounds
    self.x = math.min(math.max(self.x + dx, self.width/2),  400 - self.width/2)
    self.y = math.min(math.max(self.y + dy, self.minY),      240 - self.height/2)
    self.baseY = self.y

    if dx ~= 0 then
        -- Running animation
        self.isRunning = true
        self.runTimer += 1
        if self.runTimer >= self.framesPerRunFrame then
            self.runTimer = 0
            self.runFrameIndex = (self.runFrameIndex % #self.runImages) + 1
        end
        local imgRun = self.runImages[self.runFrameIndex]
        self.sprite:setImage(imgRun)
        self.sprite:setImageFlip(
            self.lastDirection == "left" and gfx.kImageFlippedX or gfx.kImageUnflipped,
            false
        )
        self.sprite:moveTo(self.x, self.y)
    else
        -- Idle frame
        if self.isRunning then self.isRunning, self.runFrameIndex, self.runTimer = false, 1, 0 end
        if     self.lastDirection == "down"  then self.sprite:setImage(self.imageDown)
        elseif self.lastDirection == "up"    then self.sprite:setImage(self.imageUp)
        else self.sprite:setImage(self.imageNeutral) end

        self.sprite:setImageFlip(
            self.lastDirection == "left" and gfx.kImageFlippedX or gfx.kImageUnflipped,
            false
        )
        self.sprite:moveTo(self.x, self.y)
    end
end

return Player
