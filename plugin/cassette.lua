local Cassette = require("cassette")
Cassette.setup()

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

-- HACK: all commands below do not use the defined architecture and need to be organized/refactored
vim.api.nvim_create_user_command("CassettePlaylistEntries", function()
	local playlist =
		require("cassette.players.manager").focus.connection:send({ command = { "get_property", "playlist" } }).data

	local list = {}

	for _, v in ipairs(playlist) do
		local filename = v["filename"]:match("([^/]+)$")
		table.insert(list, filename)
	end

	for i, v in ipairs(list) do
		print(i .. ": " .. v .. "\n")
	end
end, {})

vim.api.nvim_create_user_command("CassettePlaylistSet", function(opts)
	require("cassette.players.manager").focus.connection:send({
		command = { "set_property", "playlist-pos", opts.args },
	})
end, {
	nargs = 1,
})

vim.api.nvim_create_user_command("CassetteStatusline", function()
	vim.notify(require("cassette.ui.statusline").get())
end, {})

vim.api.nvim_create_user_command("CassetteInspectFocus", function()
	vim.notify(vim.inspect(require("cassette.players.manager").focus))
end, {})

vim.api.nvim_create_user_command("CassetteUnfocus", function()
	require("cassette.players.manager").focus = nil
end, {})

vim.api.nvim_create_user_command("CassetteTime", function()
	local time_pos =
		require("cassette.players.manager").focus.connection:send({ command = { "get_property", "time-pos" } })
	require("cassette.utils.logger").info("TEST", vim.inspect(time_pos))
end, {})
