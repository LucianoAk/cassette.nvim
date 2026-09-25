local cassette = {}

local player = require("cassette.player")
local ui = require("cassette.ui")

function cassette.startVideo(source)
	local videoPlayer = player.new(source)
	videoPlayer:startVideo()
end

function cassette.startMusic(source)
	local musicPlayer = player.new(source)
	musicPlayer:startMusic()
end

function cassette.getUIStatusLine()
	return ui.getStatusLine()
end

return cassette
