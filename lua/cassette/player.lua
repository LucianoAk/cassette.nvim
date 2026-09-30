local executor = require("cassette.utils.executor")
local ipc = require("cassette.utils.ipc")
local identifier = require("cassette.utils.identifier")

local Player = {}
Player.__index = Player

Player.focus = nil

local opts = {}
Player.running_players = {}

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

local function _remove_player(target_player)
	for index, player in ipairs(Player.running_players) do
		if player == target_player then
			os.remove(player.socket)
			table.remove(Player.running_players, index)
		end
	end
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
			_remove_player(self)
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
	local connection = ipc.connect(socket, function(line)
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
	ipc.send(self.connection, { command = { "loadfile", source } })
end

function Player:stop()
	return ipc.send(self.connection, { command = { "stop" } })
end

function Player.change_focus(player)
	Player.focus = player
	vim.notify("Focusing on player: " .. (player.title or ""))
	Player.focus:updateMediaFields()
end

function Player:updateMediaFields()
	self.title = ipc.send(self.connection, { command = { "get_property", "media-title" } })
	self.path = ipc.send(self.connection, { command = { "get_property", "path" } })
end

function Player:getTitle()
	return self.title
end

function Player:getPath()
	return self.path
end

return Player
