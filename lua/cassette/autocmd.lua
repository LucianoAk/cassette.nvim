local ui = require("cassette.ui")
local player = require("cassette.player")

local augroup = vim.api.nvim_create_augroup("CasssetteUICache", { clear = true })

vim.api.nvim_create_autocmd("User", {
	group = augroup,
	pattern = "UpdateUICache",
	callback = function(ev)
		player.focus:updateMediaFields()
		ui.updateCache()
		vim.cmd.redrawstatus()
	end,
})
