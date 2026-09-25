local executor = {}

function executor.run(cmd, opts)
	opts = opts or {}

	local args = cmd
	if type(cmd) == "string" then
		if vim.uv.os_uname().sysname == "Windows_NT" then
			args = { "cmd.exe", "/c", cmd }
		else
			args = { "sh", "-c", cmd }
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

return executor
