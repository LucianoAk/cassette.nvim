local executor = {}

function executor.run(cmd, opts)
	opts = opts or {}

	local args = cmd
	if type(cmd) == "string" then
		args = {}
		for word in cmd:gmatch("%S+") do
			table.insert(args, word)
		end
	end

	local handle
	handle = vim.system(args, opts.system_opts or {}, function(result)
		if opts.on_exit then
			vim.schedule(function()
				opts.on_exit(result, handle)
			end)
		end
	end)

	if opts.on_start and handle then
		opts.on_start(handle)
	end

	return handle
end

function executor.watch_pid(pid, on_exit)
	local timer = vim.uv.new_timer()

	if not timer then
		return nil, "Could not restore connection with sockets processes timer could not be initialized"
	end

	timer:start(
		0,
		1000,
		vim.schedule_wrap(function()
			local success = vim.uv.kill(pid, 0)

			if success ~= 0 then
				timer:stop()
				timer:close()
				if on_exit then
					on_exit(pid)
				end
			end
		end)
	)
end

return executor
