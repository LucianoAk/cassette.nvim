local executor = require("cassette.utils.executor")
local ipc = require("cassette.utils.ipc")

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

local function _defineSocket(template)
	if not template:find("%%") then
		template = template .. "-%d"
	end

	return string.format(template, vim.uv.hrtime())
end

local function _setupProcess(self)
	local base_args = {
		"mpv",
		"--input-ipc-server=" .. self.socket,
	}

	if self.default_volume ~= nil then
		table.insert(base_args, "--volume=" .. tostring(self.volume))
	end

	if self.default_speed ~= nil then
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

	return handle
end

local function _setupObserver(connection)
	ipc.send(connection, { command = { "observe_property", 1, "path" } })
	ipc.send(connection, { command = { "observe_property", 2, "playlist-pos" } })
	ipc.send(connection, { command = { "observe_property", 3, "pause" } })
	ipc.send(connection, { command = { "observe_property", 4, "media-title" } })
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

local Player = {}
Player.__index = Player

Player.focus = nil

function Player.new(source, defaultValues)
	local self = setmetatable({}, Player)

	self.volume = defaultValues.volume
	self.speed = defaultValues.speed
	self.video = defaultValues.video
	self.source = source

	self.title = nil
	self.path = nil

	self.socket = _defineSocket("/tmp/" .. defaultValues.socket_name_template)
	self.process = _setupProcess(self)

	local socket_ok = vim.wait(1000, function()
		return vim.uv.fs_stat(self.socket) ~= nil
	end, 10)

	if not socket_ok then
		vim.notify("Timed out waiting for MPV socket file: " .. self.socket, vim.log.levels.ERROR)
		return nil
	end

	self.connection, error = _setupConnection(self.socket)
	if error then
		vim.notify("Error: " .. error, vim.log.levels.ERROR)
		return
	end

	Player.focus = self

	_setupObserver(self.connection)

	return self
end

function Player:updateMediaFields()
	self.title = ipc.send(self.connection, { command = { "get_property", "media-title" } })
	self.path = ipc.send(self.connection, { command = { "get_property", "path" } })
end

function Player:load(source)
	self.source = source
	ipc.send(self.connection, { command = { "loadfile", source } })
end

function Player:getTitle()
	return self.title
end

function Player:getPath()
	return self.path
end

function Player:stop()
	ipc.send(self.connection, { command = { "unobserve_property", 1 } })
	ipc.send(self.connection, { command = { "unobserve_property", 2 } })
	ipc.send(self.connection, { command = { "unobserve_property", 3 } })
	ipc.send(self.connection, { command = { "unobserve_property", 4 } })
	return ipc.send(self.connection, { command = { "stop" } })
end

return Player
