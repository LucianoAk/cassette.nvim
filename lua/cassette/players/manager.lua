local IpcConnection = require("cassette.connection.ipc")
local Logger = require("cassette.utils.logger")

local PlayerManager = {}
PlayerManager.__index = PlayerManager

PlayerManager.focus = nil
PlayerManager.running_players = {}

PlayerManager.opts = {}

local MODULE_ORIGIN = "Player Manager"

-- TODO: decide where and when upadte player fields(title, video, volume, ...), current idea: update manualy and only retrieve property when sync
function PlayerManager.setup(player_configs)
	PlayerManager.opts = player_configs
end

function PlayerManager.change_focus(index)
	if not (index >= 1 and index <= #PlayerManager.running_players) then
		Logger.warn(MODULE_ORIGIN, "PlayerManager: player index not in the bounds of the list of running players")
		return
	end

	PlayerManager.focus = PlayerManager.running_players[index]
end

function PlayerManager.add(player)
	if not player.process then
		Logger.warn(
			MODULE_ORIGIN,
			"PlayerManager: cannot add player to 'running_players' table, process is not established, 'build' player before adding"
		)
		return
	end

	table.insert(PlayerManager.running_players, player)
end

function PlayerManager.load(path)
	if not PlayerManager.focus then
		Logger.warn(MODULE_ORIGIN, "could not complete 'load' request, no player is being focused")
		return
	end
	local player = PlayerManager.focus
	local _, err = player.connection:send({ command = { "loadfile", path } })

	if err then
		Logger.warn(MODULE_ORIGIN, "could not complete 'load' request to player, cause:\n" .. err)
		return
	end
end

function PlayerManager.stop()
	if not PlayerManager.focus then
		Logger.warn(MODULE_ORIGIN, "could not complete 'stop' request, no player is being focused")
		return
	end
	local player = PlayerManager.focus
	local _, err = player.connection:send({ command = { "stop" } })

	if err then
		Logger.warn(MODULE_ORIGIN, "could not complete 'stop' request to player, cause:\n" .. err)
		return
	end
end

function PlayerManager.seek(time)
	if not PlayerManager.focus then
		Logger.warn(MODULE_ORIGIN, "could not complete 'seek' request, no player is being focused")
		return
	end
	local player = PlayerManager.focus
	local _, err = player.connection:send({ command = { "seek", time } })

	if err then
		Logger.warn(MODULE_ORIGIN, "could not complete 'seek' request to player, cause:\n" .. err)
		return
	end
end

function PlayerManager.next()
	if not PlayerManager.focus then
		Logger.warn(MODULE_ORIGIN, "could not complete 'next' request, no player is being focused")
		return
	end
	local player = PlayerManager.focus
	local _, err = player.connection:send({ command = { "playlist-next" } })

	if err then
		Logger.warn(MODULE_ORIGIN, "could not complete 'seek' request to player, cause:\n" .. err)
		return
	end

	player.playlist_pos = player.playlist_pos + 1
end

function PlayerManager.previous()
	if not PlayerManager.focus then
		Logger.warn(MODULE_ORIGIN, "could not complete 'previous' request, no player is being focused")
		return
	end
	local player = PlayerManager.focus
	local _, err = player.connection:send({ command = { "playlist-prev" } })

	if err then
		Logger.warn(MODULE_ORIGIN, "could not complete 'previous' request to player, cause:\n" .. err)
		return
	end

	player.playlist_pos = player.playlist_pos - 1
end

function PlayerManager.toggle_playback()
	if not PlayerManager.focus then
		Logger.warn(MODULE_ORIGIN, "could not complete 'toggle_playback' request, no player is being focused")
		return
	end
	local player = PlayerManager.focus
	local _, err = player.connection:send({ command = { "cycle", "pause" } })

	if err then
		Logger.warn(MODULE_ORIGIN, "could not complete 'toggle_playback' request to player, cause:\n" .. err)
		return
	end

	player.pause = not player.pause
end

function PlayerManager.sync()
	if not PlayerManager.focus then
		Logger.warn(MODULE_ORIGIN, "could not complete 'sync' request, no player is being focused")
		return
	end
	local player = PlayerManager.focus

	local function get_prop(name)
		local res, err = player.connection:send({ command = { "get_property", name } })

		if err then
			Logger.warn(MODULE_ORIGIN, "could not complete 'sync' request to player, cause:\n" .. err)
			return nil
		end

		return res and res.data or nil
	end

	player.path = get_prop("path") or player.path
	player.title = get_prop("media-title") or player.title
	player.video = not not get_prop("video") or player.video
	player.volume = get_prop("volume") or player.volume
	player.speed = get_prop("speed") or player.speed
	player.pause = not not get_prop("pause") or player.pause
	player.playlist_pos = get_prop("playlist-pos") or player.playlist_pos
	player.playlist_count = get_prop("playlist-count") or player.playlist_count
end

function PlayerManager.search_active_sockets()
	local path = PlayerManager.opts.socket_path
	local template = PlayerManager.opts.socket_name_template

	if not path:match("/$") then
		path = path .. "/"
	end

	if
		not template:find("%uuid", 1, true)
		and not template:find("%nanoid", 1, true)
		and not template:find("%hrtime", 1, true)
	then
		template = template .. "-%hrtime"
	end

	local placeholder = "___WILD_FLAG___"
	local modified = template:gsub("%%uuid", placeholder):gsub("%%nanoid", placeholder):gsub("%%hrtime", placeholder)
	local pattern = "^" .. vim.pesc(modified):gsub(placeholder, ".+") .. "$"

	local handle = vim.loop.fs_scandir(path)
	if not handle then
		return {}
	end

	local active_sockets = {}
	while true do
		local name, type = vim.loop.fs_scandir_next(handle)
		if not name then
			break
		end

		if (type == "socket") and name:match(pattern) then
			local socket_path = path .. name
			local success = IpcConnection.ping(socket_path)
			if success then
				table.insert(active_sockets, socket_path)
			end
		end
	end

	return active_sockets
end

return PlayerManager
