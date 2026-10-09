local BaseBuilder = require("cassette.players.builders.base")
local IpcConnection = require("cassette.connection.ipc")
local Executor = require("cassette.utils.executor")
local Identifier = require("cassette.utils.identifier")
local Handler = require("cassette.players.handler")
local Logger = require("cassette.utils.logger")

local MpvBuilder = {}
MpvBuilder.__index = MpvBuilder
setmetatable(MpvBuilder, { __index = BaseBuilder })

local MODULE_ORIGIN = "MPV Builder"
function MpvBuilder.new()
	local self = BaseBuilder.new()
	setmetatable(self, MpvBuilder)

	self._socket = ""
	self._process = {}
	self._connection = {}

	return self
end

function MpvBuilder:socket(path, template)
	if self.err then
		return self
	end

	if not path:match("/$") then
		path = path .. "/"
	end

	local file
	if template:find("%uuid", 1, true) then
		file = string.gsub(template, "%%uuid", Identifier.uuid())
	elseif template:find("%nanoid", 1, true) then
		file = string.gsub(template, "%%nanoid", Identifier.nanoid())
	elseif template:find("%hrtime", 1, true) then
		file = string.gsub(template, "%%hrtime", Identifier.hrtime())
	else
		template = template .. "-%hrtime"
		file = string.gsub(template, "%%hrtime", Identifier.hrtime())
	end

	self._socket = path .. file
	return self
end

function MpvBuilder:process(extras_args)
	if self.err then
		return self
	end

	if not self._socket then
		self.err = Logger.build_err(MODULE_ORIGIN, "cannot create process define socket before process")
		return self
	end

	local base_args = {
		"mpv",
		"--input-ipc-server=" .. self._socket,
	}

	if self._volume ~= nil then
		table.insert(base_args, "--volume=" .. tostring(self._volume))
	end
	if self._speed ~= nil then
		table.insert(base_args, "--speed=" .. tostring(self._speed))
	end
	if self._video == false then
		table.insert(base_args, "--no-video")
	end
	if self._path and self.path ~= "" then
		table.insert(base_args, self._path)
	end
	if extras_args and #extras_args > 0 then
		for _, v in ipairs(base_args) do
			table.insert(base_args, v)
		end
	end

	local handle = Executor.run(base_args, {
		on_start = function(h)
			Logger.info(MODULE_ORIGIN, "Starting player with PID: " .. h.pid)
		end,
		on_exit = function(result)
			if result.code ~= 0 then
				Logger.error(
					MODULE_ORIGIN,
					string.format("--- Error (Exit code: %d) ---\n%s", result.code, result.stderr)
				)
			end
		end,
	})

	if not vim.wait(1000, function()
		return handle ~= nil
	end, 10) then
		self.err = Logger.build_err(MODULE_ORIGIN, "timed out waiting for process to initialize")
		return self
	end

	if not vim.wait(1000, function()
		return vim.uv.fs_stat(self._socket) ~= nil
	end, 10) then
		vim.uv.kill(handle.pid, "sigkill")

		self.err = Logger.build_err(
			MODULE_ORIGIN,
			string.format(
				"Timeout while waiting for socket file: %s\nPossible reasons:\n- Process crashed or failed to start\n- Startup took longer than 1000ms\n- Missing parent directory or permissions\n- Stale socket file or working directory mismatch",
				self._socket
			)
		)
		return self
	end

	local _, err = Executor.watch_pid(handle.pid, function(pid)
		Handler.end_process(self, require("cassette.players.manager").running_players)
		Logger.info(MODULE_ORIGIN, "Stopped player PID: " .. pid)
	end)

	if err then
		self.err = Logger.build_err(err.origin, err.message)
		return self
	end

	self._proces = handle

	return self
end

function MpvBuilder:connection()
	if self.err then
		return self
	end

	local connection, err
	connection, err = IpcConnection.new(self._socket, function(msg)
		Handler.ipc_message(connection, msg)
	end)

	if err then
		self.err = Logger.build_err(MODULE_ORIGIN, err)
		return self
	end

	if not connection then
		self.err = Logger.build_err(MODULE_ORIGIN, "failed to create connection to MPV socket")
		return self
	end

	if not vim.wait(1000, function()
		return connection and connection.is_connected
	end, 10) then
		connection:close()
		self.err = Logger.build_err(MODULE_ORIGIN, "timed out establishing connection to MPV socket")
		return self
	end

	self._connection = connection

	return self
end

function MpvBuilder.restore(socket)
	local self
	local connection, err
	connection, err = IpcConnection.new(socket, function(msg)
		Handler.ipc_message(connection, msg)
	end)

	if err then
		self.err = Logger.build_err(MODULE_ORIGIN, err)
		return self
	end

	if not connection then
		self.err = Logger.build_err(MODULE_ORIGIN, "failed to create connection to MPV socket")
		return self
	end

	if not vim.wait(1000, function()
		return connection and connection.is_connected
	end, 10) then
		connection:close()
		self.err = Logger.build_err(MODULE_ORIGIN, "timed out establishing connection to MPV socket")
		return self
	end

	local function get_prop(name)
		local res = connection:send({ command = { "get_property", name } })
		return res and res.data or nil
	end

	self = MpvBuilder.new()
		:path(get_prop("path"))
		:title(get_prop("media-title"))
		:video(not not get_prop("video"))
		:volume(get_prop("volume"))
		:speed(get_prop("speed"))
		:pause(not not get_prop("pause"))
		:playlist_pos(get_prop("playlist-pos"))
		:playlist_count(get_prop("playlist-count"))

	self._socket = socket
	self._process = { pid = get_prop("pid") }
	self._connection = connection

	Executor.watch_pid(self._process.pid, function(pid)
		Handler.end_process(self, require("cassette.players.manager").running_players)
		Logger.info(MODULE_ORIGIN, "Stopped player PID: " .. pid)
	end)

	if err then
		self.err = Logger.build_err(err.origin, err.message)
		return self
	end

	return self
end

function MpvBuilder:build()
	if self.err then
		return nil, self.err
	end
	return require("cassette.players.mpv").new(self)
end

return MpvBuilder
