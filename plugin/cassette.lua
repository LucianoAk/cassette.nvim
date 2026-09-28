local cassette = require("cassette")
cassette.setup()

vim.api.nvim_create_user_command("VideoCassetteStart", function(opts)
	cassette.startVideo(opts.args)
end, {
	nargs = 1,
})

vim.api.nvim_create_user_command("MusicCassetteStart", function(opts)
	cassette.startMusic(opts.args)
end, {
	nargs = 1,
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
