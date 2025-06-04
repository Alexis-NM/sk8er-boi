import "CoreLibs/graphics"
import "CoreLibs/sprites"
local pd  <const> = playdate
local gfx <const> = pd.graphics

local Level1 = {}

-- Initialize level 1, set up background and scrolling
function Level1.init()
    -- Load the background image
    Level1.bgImage = gfx.image.new("assets/images/background")

    -- Get background dimensions
    Level1.bgWidth, Level1.bgHeight = Level1.bgImage:getSize()

    -- Scrolling speed in pixels per frame
    Level1.bgScrollSpeed = 2

    -- Initial scroll position
    Level1.scrollX = 0

    -- Level start flag (activated by main.lua)
    Level1.isLevelStarted = false

    -- Ground Y position (for future obstacles)
    Level1.groundY = 200

    -- Draw background before sprites, tile horizontally
    gfx.sprite.setBackgroundDrawingCallback(function(x, y, w, h)
        Level1.bgImage:draw(-Level1.scrollX, 0)
        Level1.bgImage:draw(-Level1.scrollX + Level1.bgWidth, 0)
    end)
end

-- Advance the background scroll each frame when the level is active
function Level1.updateScroll()
    Level1.scrollX = (Level1.scrollX + Level1.bgScrollSpeed) % Level1.bgWidth
end

return Level1