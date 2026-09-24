local methods = {}

methods.start = function(source)
	local command = source.format("mpv --input-ipc-server=/tmp/mpv-$$-socket --cache=no %s", source)
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
end

return methods
