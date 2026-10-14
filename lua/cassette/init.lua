local cassette = {}

local player_manager = require("cassette.players.manager")
local mpv_player = require("cassette.players.mpv")
local logger = require("cassette.utils.logger")
local ui = require("cassette.ui.ui")
local config = require("cassette.config")
local autocmd = require("cassette.autocmd")

function cassette.setup(user_opts)
	config.setup(user_opts)
	player_manager.setup(config.options.player)
	autocmd.setup(config.options.session)

	if config.options.session.persist and config.options.session.persist == true then
		vim.schedule(function()
			vim.api.nvim_exec_autocmds("User", {
				pattern = "ReconnectSockets",
			})
		end)
	end
end

function cassette.startVideo(path)
	local video_player, err = mpv_player
		.builder()
		:path(path)
		:video(true)
		:socket(player_manager.opts.socket_path, player_manager.opts.socket_name_template)
		:process()
		:connection()
		:build()

	if err then
		logger.error(err.origin, err.message)
		return
	end

	player_manager.add(video_player)
end

function cassette.startMusic(path)
	local music_player, err = mpv_player
		.builder()
		:path(path)
		:video(false)
		:socket(player_manager.opts.socket_path, player_manager.opts.socket_name_template)
		:process()
		:connection()
		:build()

	if err then
		logger.error(err.origin, err.message)
		return
	end

	player_manager.add(music_player)
end

function cassette.load(path)
	player_manager.load(path)
end

function cassette.stop()
	player_manager.stop()
end

function cassette.seek(time)
	player_manager.seek(time)
end

function cassette.next()
	player_manager.next()
end

function cassette.previous()
	player_manager.previous()
end

function cassette.toggle_playback()
	player_manager.toggle_playback()
end

function cassette.focus()
	ui.show_player_picker(player_manager.running_players, function(p)
		return string.format("▶ Player: %s", p.title or "")
	end, function(choice, index)
		if choice then
			player_manager.change_focus(index)
			vim.schedule(function()
				vim.api.nvim_exec_autocmds("User", {
					pattern = "UpdateUICache",
				})
			end)
		end
	end)
end

function cassette.getUIStatusLine()
	return ui.getStatusLine()
end

return cassette
