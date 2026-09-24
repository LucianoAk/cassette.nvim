vim.api.nvim_create_user_command("CassetteStart", function(opts)
	require("cassette").start(opts.args)
end, {
	nargs = 1,
	complete = "file",
})
