vim.api.nvim_create_user_command("VideoCassetteStart", function(opts)
	require("cassette").startVideo(opts.args)
end, {
	nargs = 1,
})
