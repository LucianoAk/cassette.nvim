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

vim.api.nvim_create_autocmd("User", {
	group = augroup,
	pattern = "CleanUICache",
	callback = function(ev)
		ui.cleanCache()

		local ok = vim.wait(1000, function()
			return ui.cache.mediaTitle == "" and ui.cache.path == ""
		end, 100)

		if not ok then
			vim.notify("Timeout", vim.log.levels.ERROR)
		end

		vim.cmd.redrawstatus()
	end,
})
