local cassette = {}

local player = require("cassette.player")
local ui = require("cassette.ui")
local config = require("cassette.config")
local autocmd = require("cassette.autocmd")

function cassette.setup(user_opts)
	config.setup(user_opts)
	player.setup(config.options.player)
	autocmd.setup({ persist = config.options.player.persist })
end

function cassette.startVideo(source)
	local videoPlayer = player.new(true, source)

	if not videoPlayer then
		vim.notify("Failed to start player: MPV player could not be initialized.", vim.log.levels.ERROR)
		return
	end
end

function cassette.startMusic(source)
	local musicPlayer = player.new(false, source)

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

function cassette.focus()
	ui.show_player_picker(player.running_players, function(p)
		return string.format("▶ Player: %s", p.title or "")
	end, function(choice)
		player.change_focus(choice)
		ui.updateCache(choice.title, choice.path)
	end)
end

function cassette.getUIStatusLine()
	return ui.getStatusLine()
end

return cassette
