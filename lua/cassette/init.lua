local cassette = {}

local player = require("cassette.player")

function cassette.startVideo(source)
	local videoPlayer = player.new(source)
	videoPlayer:startVideo()
end

function cassette.startMusic(source)
	local musicPlayer = player.new(source)
	musicPlayer:startMusic()
end

return cassette
