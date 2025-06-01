import "CoreLibs/graphics"
import "CoreLibs/sprites"
local gfx <const> = playdate.graphics
local pd  <const> = playdate

local Player = {}

function Player:init()
    self.imageRight = gfx.image.new("assets/sprites/skater") or error("failed to load skater.png")
    self.imageUp    = gfx.image.new("assets/sprites/skater_up") or error("failed to load skater_up.png")
    self.imageDown  = gfx.image.new("assets/sprites/skater_down") or error("failed to load skater_down.png")

    self.sprite = gfx.sprite.new(self.imageRight)
    self.x, self.y = 200, 120
    self.width, self.height = self.imageRight:getSize()
    self.speed = 2
    self.facingLeft = false
    self.lastDirection = "right"

    self.sprite:setImage(self.imageRight)
    self.sprite:setImageFlip(gfx.kImageUnflipped, false)
    self.sprite:moveTo(self.x, self.y)
    self.sprite:add()
end

function Player:update()
    if not self.sprite then return end

    local dx, dy = 0, 0
    if pd.buttonIsPressed(pd.kButtonLeft)  then dx = -self.speed
    elseif pd.buttonIsPressed(pd.kButtonRight) then dx =  self.speed end
    if pd.buttonIsPressed(pd.kButtonUp)    then dy = -self.speed
    elseif pd.buttonIsPressed(pd.kButtonDown) then dy =  self.speed end

    if     dy > 0 then self.lastDirection = "down"
    elseif dy < 0 then self.lastDirection = "up"
    elseif dx < 0 then self.lastDirection = "left"
    elseif dx > 0 then self.lastDirection = "right"
    end

    if     self.lastDirection == "down" then
        self.sprite:setImage(self.imageDown)
        self.sprite:setImageFlip(gfx.kImageUnflipped, false)
    elseif self.lastDirection == "up" then
        self.sprite:setImage(self.imageUp)
        self.sprite:setImageFlip(gfx.kImageUnflipped, false)
    else
        self.sprite:setImage(self.imageRight)
        if self.lastDirection == "left" then
            self.facingLeft = true
            self.sprite:setImageFlip(gfx.kImageFlippedX, false)
        else
            self.facingLeft = false
            self.sprite:setImageFlip(gfx.kImageUnflipped, false)
        end
    end

    self.x = math.min(math.max((self.x or 0) + dx, self.width/2),  400 - self.width/2)
    self.y = math.min(math.max((self.y or 0) + dy, self.height/2), 240 - self.height/2)

    self.sprite:moveTo(self.x, self.y)
end

return Player
