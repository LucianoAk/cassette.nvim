local cassette = require("cassette")
cassette.setup()

-- TODO: fix the error with path with spaces in name
vim.api.nvim_create_user_command("VideoCassetteStart", function(opts)
	cassette.startVideo(opts.args)
end, {
	nargs = 1,
	complete = "file",
})

vim.api.nvim_create_user_command("MusicCassetteStart", function(opts)
	cassette.startMusic(opts.args)
end, {
	nargs = 1,
	complete = "file",
})

vim.api.nvim_create_user_command("GetUIStatusLine", function()
	local status_text = cassette.getUIStatusLine()
	vim.notify(status_text)
end, {})

vim.api.nvim_create_user_command("CassetteLoad", function(opts)
	cassette.load(opts.args)
end, {
	nargs = 1,
})

vim.api.nvim_create_user_command("CassetteStop", function()
	cassette.stop()
end, {})

vim.api.nvim_create_user_command("CassetteSeek", function(opts)
	cassette.seek(opts.args)
end, {
	nargs = 1,
})

vim.api.nvim_create_user_command("CassetteNext", function()
	cassette.next()
end, {})

vim.api.nvim_create_user_command("CassettePrev", function()
	cassette.previous()
end, {})

vim.api.nvim_create_user_command("CassetteTogglePlayback", function()
	cassette.toggle_playback()
end, {})

vim.api.nvim_create_user_command("CassetteFocus", function()
	cassette.focus()
end, {})
