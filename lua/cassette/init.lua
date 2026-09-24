local cassette = {}

local player = require("cassette.player")

function cassette.start(source)
	player.startVideo(source)
end

return cassette
