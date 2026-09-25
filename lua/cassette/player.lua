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

local executor = require("cassette.utils.executor")

function Player:startVideo()
	local pid = executor.run("mpv --input-ipc-server=/tmp/mpv-$$-socket " .. self.source, {
		on_start = function(handle)
			vim.notify("Started player with PID: " .. handle.pid, vim.log.levels.INFO)
		end,
		on_exit = function(result, handle)
			if result.code == 0 then
				vim.notify("Stopped player PID: " .. handle.pid, vim.log.levels.INFO)
			else
				print("--- Error (Exit code: " .. result.code .. ") ---\n" .. result.stderr)
				vim.notify("--- Error (Exit code: " .. result.code .. ") ---\n" .. result.stderr, vim.log.levels.ERROR)
			end
		end,
	}).pid
	self.socket = "/tmp/mpv-" .. pid .. "-socket"
end

function Player:startMusic()
	local pid = executor.run("mpv --input-ipc-server=/tmp/mpv-$$-socket --no-video " .. self.source, {
		on_start = function(handle)
			vim.notify("Started player with PID: " .. handle.pid, vim.log.levels.INFO)
		end,
		on_exit = function(result, handle)
			if result.code == 0 then
				vim.notify("Stopped player PID: " .. handle.pid, vim.log.levels.INFO)
			else
				print("--- Error (Exit code: " .. result.code .. ") ---\n" .. result.stderr)
				vim.notify("--- Error (Exit code: " .. result.code .. ") ---\n" .. result.stderr, vim.log.levels.ERROR)
			end
		end,
	}).pid
	self.socket = "/tmp/mpv-" .. pid .. "-socket"
end

local function getProperty(socket, property)
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

return Player
