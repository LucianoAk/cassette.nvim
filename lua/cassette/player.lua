local executor = require("cassette.utils.executor")
local connector = require("cassette.utils.connector")
local identifier = require("cassette.utils.identifier")

local Player = {}
Player.__index = Player

Player.focus = nil

local opts = {}
Player.running_players = {}

-- TODO:
-- add toggling playback method that also updates the ui so it can make the icon 󰏤, 󰏥, 󰏧 or 󰏦
-- add support for streamlink (add extractor module)
-- add set audio functionality
-- add playlist-play-index
-- detect and save plataform in Player fields
function Player.setup(player_configs)
	opts = player_configs
end

local function _handleMpvNessage(msg)
	local trigger_event = nil

	if msg.event == "end-file" then
		trigger_event = "CleanUICache"
	elseif msg.event == "file-loaded" then
		trigger_event = "UpdateUICache"
	elseif msg.name == "path" or msg.name == "playlist-pos" then
		trigger_event = "UpdateUICache"
	end

	if trigger_event then
		vim.schedule(function()
			vim.api.nvim_exec_autocmds("User", {
				pattern = trigger_event,
			})
		end)
	end
end

local function _defineSocket(path, template)
	if not path:match("/$") then
		path = path .. "/"
	end

	local file
	if template:find("%uuid", 1, true) then
		file = string.gsub(template, "%%uuid", identifier.uuid())
	elseif template:find("%nanoid", 1, true) then
		file = string.gsub(template, "%%nanoid", identifier.nanoid())
	elseif template:find("%hrtime", 1, true) then
		file = string.gsub(template, "%%hrtime", identifier.hrtime())
	else
		template = template .. "-%hrtime"
		file = string.gsub(template, "%%hrtime", identifier.hrtime())
	end

	return path .. file
end

local function _setupProcess(self)
	local base_args = {
		"mpv",
		"--input-ipc-server=" .. self.socket,
	}

	if self.volume ~= nil then
		table.insert(base_args, "--volume=" .. tostring(self.volume))
	end

	if self.speed ~= nil then
		table.insert(base_args, "--speed=" .. tostring(self.speed))
	end

	if self.video == false then
		table.insert(base_args, "--no-video")
	end

	if self.source and self.source ~= "" then
		table.insert(base_args, self.source)
	end

	local cmd = table.concat(base_args, " ")
	local handle = executor.run(cmd, {
		on_start = function(h)
			vim.notify("Starting player with PID: " .. h.pid, vim.log.levels.INFO)
		end,
		on_exit = function(result, h)
			for index, player in ipairs(Player.running_players) do
				if player == self then
					os.remove(player.socket)
					table.remove(Player.running_players, index)
				end
			end
			if result.code == 0 then
				vim.notify("Stopped player PID: " .. h.pid, vim.log.levels.INFO)
			else
				local err_msg = string.format("--- Error (Exit code: %d) ---\n%s", result.code, result.stderr)
				vim.notify(err_msg, vim.log.levels.ERROR)
			end
		end,
	})

	local process_ok = vim.wait(1000, function()
		return handle ~= nil
	end, 10)

	if not process_ok then
		vim.notify("Timed out waiting for process to initialize", vim.log.levels.ERROR)
		return nil
	end

	local socket_ok = vim.wait(1000, function()
		return vim.uv.fs_stat(self.socket) ~= nil
	end, 10)

	if not socket_ok then
		handle:kill("sigterm")
		return nil,
			string.format(
				"Timeout while waiting for socket file: %s\nPossible reasons:\n- Process crashed or failed to start\n- Startup took longer than 1000ms\n- Missing parent directory or permissions\n- Stale socket file or working directory mismatch",
				self.socket
			)
	end

	return handle
end

local function _setupConnection(socket)
	local connection = connector.connect(socket, function(line)
		_handleMpvNessage(line)
	end)

	if not connection then
		return nil, "Failed to create connection to MPV socket."
	end

	local conn_ok = vim.wait(1000, function()
		return connection and connection.is_connected
	end, 10)

	if not conn_ok then
		connection:close()
		return nil, "Timed out establishing connection to MPV socket."
	end

	return connection
end

function Player.new(video, source)
	local self = setmetatable({}, Player)

	self.volume = opts.default_volume
	self.speed = opts.default_speed
	self.video = video
	self.source = source

	self.title = nil
	self.path = nil
	self.playlist_pos = nil
	self.playlist_count = nil
	self.pause = nil

	self.socket = _defineSocket(opts.socket_path, opts.socket_name_template)
	self.process, error = _setupProcess(self)

	if error then
		vim.notify("Error: " .. error, vim.log.levels.ERROR)
		return
	end

	self.connection, error = _setupConnection(self.socket)
	if error then
		vim.notify("Error: " .. error, vim.log.levels.ERROR)
		return
	end

	table.insert(Player.running_players, self)

	Player.focus = self

	return self
end

function Player:load(source)
	self.source = source
	connector.send(self.connection, { command = { "loadfile", source } })
end

function Player:stop()
	local response, error = connector.send(self.connection, { command = { "stop" } })
	if error then
		vim.notify(error, vim.log.levels.ERROR)
	end

	return response
end

function Player:seek(time)
	connector.send(self.connection, { command = { "seek", time } })
end

function Player:next()
	connector.send(self.connection, { command = { "playlist-next" } })
end

function Player:previous()
	connector.send(self.connection, { command = { "playlist-prev" } })
end

function Player:toggle_playback()
	local _, error = connector.send(self.connection, { command = { "cycle", "pause" } })
	if not error then
		self.pause = not self.pause
	end
end

function Player.change_focus(player)
	Player.focus = player
	vim.notify("Focusing on player: " .. (player.title or ""))
	Player.focus:updateMediaFields()
end

function Player:updateMediaFields()
	self.title = connector.send(self.connection, { command = { "get_property", "media-title" } }).data
	self.path = connector.send(self.connection, { command = { "get_property", "path" } }).data
	self.playlist_pos = connector.send(self.connection, { command = { "get_property", "playlist-pos" } }).data + 1
	self.playlist_count = connector.send(self.connection, { command = { "get_property", "playlist-count" } }).data
end

function Player.search_active_sockets()
	local path = opts.socket_path
	local template = opts.socket_name_template

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
			local success = connector.ping(socket_path, 1000)
			if success then
				table.insert(active_sockets, socket_path)
			end
		end
	end

	return active_sockets
end

function Player.reconnect_socket(socket)
	local connection, err = _setupConnection(socket)
	if err then
		vim.notify("Error: " .. err, vim.log.levels.ERROR)
	else
		local function get_prop(name)
			local res = connector.send(connection, { command = { "get_property", name } })
			return res and res.data or nil
		end

		local self = setmetatable({
			socket = socket,
			connection = connection,
			volume = get_prop("volume"),
			speed = get_prop("speed"),
			video = not not get_prop("video"),
			source = get_prop("path"),
			title = get_prop("media-title"),
			path = get_prop("path"),
			playlist_pos = get_prop("playlist-pos") + 1,
			playlist_count = get_prop("playlist-count"),
			pause = not not get_prop("pause"),
			process = { pid = get_prop("pid") },
		}, Player)

		executor.watch_pid(self.process.pid, function(pid)
			for index, player in ipairs(Player.running_players) do
				if player == self then
					os.remove(player.socket)
					table.remove(Player.running_players, index)
				end
			end
			vim.notify("Stopped player PID: " .. pid, vim.log.levels.INFO)
		end)

		table.insert(Player.running_players, self)
	end
end

return Player
