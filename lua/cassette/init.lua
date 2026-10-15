local PlayerManager = require("cassette.players.manager")
local MpvPlayer = require("cassette.players.mpv")
local Logger = require("cassette.utils.logger")
local Statusline = require("cassette.ui.statusline")
local Popup = require("cassette.ui.popup")
local Config = require("cassette.config")
local Autocmd = require("cassette.autocmd")

local Cassette = {}

function Cassette.setup(user_opts)
	Config.setup(user_opts)
	PlayerManager.setup(Config.options.player)
	Autocmd.setup(Config.options.session)
	Statusline.setup(Config.options.ui.statusline)

	if Config.options.session.persist and Config.options.session.persist == true then
		vim.schedule(function()
			vim.api.nvim_exec_autocmds("User", {
				pattern = "ReconnectSockets",
			})
		end)
	end
end

function Cassette.startVideo(path)
	local video_player, err = MpvPlayer.builder()
		:path(path)
		:video(true)
		:socket(PlayerManager.opts.socket_path, PlayerManager.opts.socket_name_template)
		:process()
		:connection()
		:observe("pause")
		:build()

	if err then
		Logger.error(err.origin, err.message)
		return
	end

	PlayerManager.add(video_player)
end

function Cassette.startMusic(path)
	local music_player, err = MpvPlayer.builder()
		:path(path)
		:video(false)
		:socket(PlayerManager.opts.socket_path, PlayerManager.opts.socket_name_template)
		:process()
		:connection()
		:observe("pause")
		:build()

	if err then
		Logger.error(err.origin, err.message)
		return
	end

	PlayerManager.add(music_player)
end

function Cassette.load(path)
	PlayerManager.load(path)
end

function Cassette.stop()
	PlayerManager.stop()
end

function Cassette.seek(time)
	PlayerManager.seek(time)
end

function Cassette.next()
	PlayerManager.next()
end

function Cassette.previous()
	PlayerManager.previous()
end

function Cassette.toggle_playback()
	PlayerManager.toggle_playback()
end

function Cassette.focus()
	local player_select_list = {}
	for _, p in pairs(PlayerManager.running_players) do
		table.insert(player_select_list, p)
	end

	Popup.show_player_picker(player_select_list, function(p)
		return string.format("▶ Player: %s", p.title or "")
	end, function(choice)
		if choice then
			PlayerManager.change_focus(choice.id)
		end
	end)
end

function Cassette.getStatusLine()
	return Statusline.get()
end

return Cassette
