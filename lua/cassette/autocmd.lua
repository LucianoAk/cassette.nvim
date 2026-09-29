local ui = require("cassette.ui")
local player = require("cassette.player")

local autocmd = {}
local opts = {}

function autocmd.setup(autocmd_configs)
	opts = autocmd_configs or {}

	local ui_cache_group = vim.api.nvim_create_augroup("CasssetteUICache", { clear = true })

	vim.api.nvim_create_autocmd("User", {
		group = ui_cache_group,
		pattern = "UpdateUICache",
		callback = function(ev)
			player.focus:updateMediaFields()
			ui.updateCache(player.focus.title, player.focus.path)
			vim.cmd.redrawstatus()
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = ui_cache_group,
		pattern = "CleanUICache",
		callback = function(ev)
			ui.cleanCache()
			vim.cmd.redrawstatus()
		end,
	})

	local augroup = vim.api.nvim_create_augroup("PluginCleanup", { clear = true })

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = augroup,
		callback = function()
			if not opts.persist or opts.persist == false then
				for _, p in ipairs(player.running_players) do
					p:stop()
				end
			end
		end,
	})
end

return autocmd
