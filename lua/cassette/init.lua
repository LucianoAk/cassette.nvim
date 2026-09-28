local cassette = {}

local player = require("cassette.player")
local ui = require("cassette.ui")
local config = require("cassette.config")
require("cassette.autocmd")

function cassette.setup(user_opts)
	config.setup(user_opts)
end

function cassette.startVideo(source)
	local player_opts = vim.deepcopy(config.options.player)
	player_opts.video = true
	local videoPlayer = player.new(source, player_opts)

	if not videoPlayer then
		vim.notify("Failed to start player: MPV player could not be initialized.", vim.log.levels.ERROR)
		return
	end
end

function cassette.startMusic(source)
	local player_opts = vim.deepcopy(config.options.player)
	player_opts.video = false

	local musicPlayer = player.new(source, player_opts)

	if not musicPlayer then
		vim.notify("Failed to start player: MPV player could not be initialized.", vim.log.levels.ERROR)
		return
	end
end

function cassette.load(source)
	player.focus:load(source)
end

function cassette.stop()
	player.focus:stop()
end

function cassette.getUIStatusLine()
	return ui.getStatusLine()
end

return cassette
