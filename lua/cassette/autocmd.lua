local ui = require("cassette.ui")
local PlayerManager = require("cassette.players.manager")
local MpvPlayer = require("cassette.players.mpv")

local autocmd = {}
local opts = {}

function autocmd.setup(autocmd_configs)
	opts = autocmd_configs or {}

	local player_field_group = vim.api.nvim_create_augroup("CassettePlayerFields", { clear = true })

	vim.api.nvim_create_autocmd("User", {
		group = player_field_group,
		pattern = "SyncPlayerFields",
		callback = function()
			PlayerManager.focus:sync()
		end,
	})

	local ui_cache_group = vim.api.nvim_create_augroup("CasssetteUICache", { clear = true })

	vim.api.nvim_create_autocmd("User", {
		group = ui_cache_group,
		pattern = "UpdateUICache",
		callback = function()
			if PlayerManager.focus then
				ui.updateCache()
			else
				ui.cleanCache()
			end
			vim.cmd.redrawstatus()
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = ui_cache_group,
		pattern = "CleanUICache",
		callback = function()
			ui.cleanCache()
			vim.cmd.redrawstatus()
		end,
	})

	local plugin_cleanup_group = vim.api.nvim_create_augroup("CassetteCleanup", { clear = true })

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = plugin_cleanup_group,
		callback = function()
			if not opts.persist or opts.persist == false then
				for _, p in ipairs(PlayerManager.running_players) do
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
			local active_sockets = PlayerManager.search_active_sockets()

			if not active_sockets or #active_sockets == 0 then
				return
			end

			if opts.reconnect_mode == "auto-reconnect" then
				for _, socket in ipairs(active_sockets) do
					PlayerManager.add(MpvPlayer.builder().restore(socket):build())
				end
			elseif opts.reconnect_mode == "ask-all" then
				ui.ask_reconnect_socket(
					"Cassette found active player sockets, do you want to reconnect?",
					function(reconnect)
						if reconnect then
							for _, socket in ipairs(active_sockets) do
								PlayerManager.add(MpvPlayer.builder().restore(socket):build())
							end
						end
					end
				)
			elseif opts.reconnect_mode == "ask-each" then
				local index = 1
				local total = #active_sockets

				local function process_next()
					if index > total then
						return
					end

					local current_index = index
					local socket = active_sockets[index]
					index = index + 1

					ui.ask_reconnect_socket(
						string.format(
							"Cassette found active socket '%s' (%d/%d), do you want to reconnect?",
							socket,
							current_index,
							total
						),
						function(reconnect)
							if reconnect then
								PlayerManager.add(MpvPlayer.builder().restore(socket):build())
							end
							process_next()
						end
					)
				end

				process_next()
			else
				vim.notify(
					string.format("Invalid configuration reconnect_mode: '%s'", opts.reconnect_mode),
					vim.log.levels.ERROR
				)
				return
			end
		end,
	})
end

return autocmd
