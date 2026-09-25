local executor = require("cassette.utils.executor")

local Player = {}
Player.__index = Player

Player.focus = nil

function Player.new(source)
	local self = setmetatable({}, Player)

	self.source = source
	self.socket = nil

	Player.focus = self

	return self
end

local function _start(source, extra_flags)
	local base_args = {
		"mpv",
		"--input-ipc-server=/tmp/mpv-$$-socket",
	}

	for _, flag in ipairs(extra_flags or {}) do
		table.insert(base_args, flag)
	end

	table.insert(base_args, source)

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

	return handle
end

function Player:startVideo()
	local pid = _start(self.source).pid
	self.socket = "/tmp/mpv-" .. pid .. "-socket"
end

function Player:startMusic()
	local pid = _start(self.source, { "--no-video" }).pid
	self.socket = "/tmp/mpv-" .. pid .. "-socket"
end

local function _getProperty(socket, property)
	local cmd_table = { command = { "get_property", property } }
	local payload = vim.fn.json_encode(cmd_table) .. "\n"

	local system_args = {}
	if vim.fn.executable("socat") == 1 then
		system_args = { "socat", "-", socket }
	elseif vim.fn.executable("nc") == 1 then
		system_args = { "nc", "-U", socket }
	else
		vim.notify("Neither socat nor nc is available for mpv IPC.", vim.log.levels.ERROR)
		return nil
	end

	local result = vim.system(system_args, {
		stdin = payload,
		text = true,
	}):wait()

	if result.code == 0 and result.stdout ~= "" then
		local ok, decoded = pcall(vim.fn.json_decode, result.stdout)
		if ok and decoded and decoded.error == "success" then
			return decoded.data
		end
	end

	return nil
end

function Player:getTitle()
	local result = _getProperty(self.socket, "media-title")
	return result
end

function Player:getPath()
	return _getProperty(self.socket, "path")
end

return Player
