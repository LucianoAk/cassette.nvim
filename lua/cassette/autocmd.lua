local augroup = vim.api.nvim_create_augroup("UpdateStatusCache", { clear = true })

vim.api.nvim_create_autocmd("User", {
	group = augroup,
	pattern = "UpdateUICache",
	callback = function(ev)
		require("cassette.ui").updateCache()
		vim.cmd.redrawstatus()
	end,
})
