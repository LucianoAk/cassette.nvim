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

return executor
