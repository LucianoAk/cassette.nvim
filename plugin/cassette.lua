vim.api.nvim_create_user_command("VideoCassetteStart", function(opts)
	require("cassette").startVideo(opts.args)
end, {
	nargs = 1,
})

vim.api.nvim_create_user_command("MusicCassetteStart", function(opts)
	require("cassette").startMusic(opts.args)
end, {
	nargs = 1,
})
