local Cassette = require("cassette")
Cassette.setup()

-- TODO: fix the error with path with spaces in name
vim.api.nvim_create_user_command("VideoCassetteStart", function(opts)
	Cassette.startVideo(opts.args)
end, {
	nargs = 1,
	complete = "file",
})

vim.api.nvim_create_user_command("MusicCassetteStart", function(opts)
	Cassette.startMusic(opts.args)
end, {
	nargs = 1,
	complete = "file",
})

vim.api.nvim_create_user_command("GetUIStatusLine", function()
	local status_text = Cassette.getUIStatusLine()
	vim.notify(status_text)
end, {})

vim.api.nvim_create_user_command("CassetteLoad", function(opts)
	Cassette.load(opts.args)
end, {
	nargs = 1,
})

vim.api.nvim_create_user_command("CassetteStop", function()
	Cassette.stop()
end, {})

vim.api.nvim_create_user_command("CassetteSeek", function(opts)
	Cassette.seek(opts.args)
end, {
	nargs = 1,
})

vim.api.nvim_create_user_command("CassetteNext", function()
	Cassette.next()
end, {})

vim.api.nvim_create_user_command("CassettePrev", function()
	Cassette.previous()
end, {})

vim.api.nvim_create_user_command("CassetteTogglePlayback", function()
	Cassette.toggle_playback()
end, {})

vim.api.nvim_create_user_command("CassetteFocus", function()
	Cassette.focus()
end, {})
