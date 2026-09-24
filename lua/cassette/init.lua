local cassette = {}

local player = require("cassette.player")

function cassette.startVideo(source)
	player.startVideo(source)
end

return cassette
