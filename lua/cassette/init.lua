local cassette = {}

local PlayerManager = require("cassette.players.manager")
local MpvPlayer = require("cassette.players.mpv")
local Logger = require("cassette.utils.logger")
local Statusline = require("cassette.ui.statusline")
local Popup = require("cassette.ui.popup")
local Config = require("cassette.config")
local Autocmd = require("cassette.autocmd")

function cassette.setup(user_opts)
	Config.setup(user_opts)
	PlayerManager.setup(Config.options.player)
	Autocmd.setup(Config.options.session)

	if Config.options.session.persist and Config.options.session.persist == true then
		vim.schedule(function()
			vim.api.nvim_exec_autocmds("User", {
				pattern = "ReconnectSockets",
			})
		end)
	end
end

function cassette.startVideo(path)
	local video_player, err = MpvPlayer.builder()
		:path(path)
		:video(true)
		:socket(PlayerManager.opts.socket_path, PlayerManager.opts.socket_name_template)
		:process()
		:connection()
		:build()

	if err then
		Logger.error(err.origin, err.message)
		return
	end

	PlayerManager.add(video_player)
end

function cassette.startMusic(path)
	local music_player, err = MpvPlayer.builder()
		:path(path)
		:video(false)
		:socket(PlayerManager.opts.socket_path, PlayerManager.opts.socket_name_template)
		:process()
		:connection()
		:build()

	if err then
		Logger.error(err.origin, err.message)
		return
	end

	PlayerManager.add(music_player)
end

function cassette.load(path)
	PlayerManager.load(path)
end

function cassette.stop()
	PlayerManager.stop()
end

function cassette.seek(time)
	PlayerManager.seek(time)
end

function cassette.next()
	PlayerManager.next()
end

function cassette.previous()
	PlayerManager.previous()
end

function cassette.toggle_playback()
	PlayerManager.toggle_playback()
end

function cassette.focus()
	Popup.show_player_picker(PlayerManager.running_players, function(p)
		return string.format("▶ Player: %s", p.title or "")
	end, function(choice, index)
		if choice then
			PlayerManager.change_focus(index)
			vim.schedule(function()
				vim.api.nvim_exec_autocmds("User", {
					pattern = "UpdateUICache",
				})
			end)
		end
	end)
end

function cassette.getUIStatusLine()
	return Statusline.getStatusLine()
end

return cassette
