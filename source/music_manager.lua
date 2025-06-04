import "CoreLibs/graphics"
local pd <const> = playdate

local MusicManager = {}

function MusicManager:init(file1, file2)
    self.sp1 = pd.sound.sampleplayer.new(file1)
    self.sp1:setVolume(1.0)

    self.sp2 = pd.sound.sampleplayer.new(file2)
    self.sp2:setVolume(1.0)

    self.running = true

    self.sp1:setFinishCallback(
        function()
            if self.running then
                self.sp2:play(0, 0)
            end
        end
    )

    self.sp2:setFinishCallback(
        function()
            if self.running then
                self.sp1:play(0, 0)
            end
        end
    )

    self.sp1:play(0, 0)
end

function MusicManager:stop()
    self.running = false
    if self.sp1 and self.sp1:isPlaying() then
        self.sp1:stop()
    end
    if self.sp2 and self.sp2:isPlaying() then
        self.sp2:stop()
    end
end

return MusicManager
