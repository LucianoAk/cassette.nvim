local cassette = {}

local player = require("cassette.player")
local ui = require("cassette.ui")
local config = require("cassette.config")
require("cassette.autocmd")

function cassette.setup(user_opts)
	config.setup(user_opts)
end

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
