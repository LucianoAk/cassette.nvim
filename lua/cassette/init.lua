local cassette = {}

local player = require("cassette.player")

function cassette.startVideo(source)
	player.startVideo(source)
end

function cassette.startMusic(source)
	player.startMusic(source)
end

return cassette
