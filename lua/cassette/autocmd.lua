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

	local plugin_cleanup_group = vim.api.nvim_create_augroup("CassetteCleanup", { clear = true })

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = plugin_cleanup_group,
		callback = function()
			if not opts.persist or opts.persist == false then
				for _, p in ipairs(player.running_players) do
					p:stop()
				end
			end
		end,
	})

	local plugin_initialization_group = vim.api.nvim_create_augroup("CassetteInit", { clear = true })

	vim.api.nvim_create_autocmd("User", {
		group = plugin_initialization_group,
		pattern = "ReconnectSockets",
		callback = function()
			local active_sockets = player.search_active_sockets()

			if not active_sockets or #active_sockets == 0 then
				return
			end

			ui.ask_reconnect_socket(function()
				player.reconnect_sockets(active_sockets)
			end)
		end,
	})
end

return autocmd
