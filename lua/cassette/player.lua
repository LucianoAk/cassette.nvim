local Player = {}
Player.__index = Player

function Player.new(source)
	local self = setmetatable({}, Player)

	self.source = source
	self.socket = nil

	return self
end

local function runCommand(command)
	local handle
	handle = vim.system({ "sh", "-c", command }, function(result)
		vim.schedule(function()
			if result.code == 0 then
				vim.notify("Stopped player PID:" .. handle.pid)
			else
				print("--- Error (Exit code: " .. result.code .. ") ---\n" .. result.stderr)
			end
		end)
	end)

	vim.notify("Started player with PID: " .. handle.pid, vim.log.levels.INFO)

	return handle.pid
end

function Player:startVideo()
	local pid = runCommand("mpv --input-ipc-server=/tmp/mpv-$$-socket " .. self.source)
	self.socket = "/tmp/mpv-" .. pid .. "-socket"
end

function Player:startMusic()
	local pid = runCommand("mpv --input-ipc-server=/tmp/mpv-$$-socket --no-video " .. self.source)
	self.socket = "/tmp/mpv-" .. pid .. "-socket"
end

return Player
