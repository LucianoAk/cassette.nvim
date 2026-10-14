local Popup = require("cassette.ui.popup")
local PlayerManager = require("cassette.players.manager")
local MpvPlayer = require("cassette.players.mpv")

local autocmd = {}
local opts = {}

function autocmd.setup(autocmd_configs)
	opts = autocmd_configs or {}

	local player_field_group = vim.api.nvim_create_augroup("CassettePlayerFields", { clear = true })

	-- TODO: pass player to autocmd instead of using focus everytime
	vim.api.nvim_create_autocmd("User", {
		group = player_field_group,
		pattern = "SyncPlayerFields",
		callback = function()
			PlayerManager.focus:sync()
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = player_field_group,
		pattern = "SyncPlayerPause",
		callback = function()
			PlayerManager.focus:sync_field("pause")
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
				Popup.ask_reconnect_socket(
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

					Popup.ask_reconnect_socket(
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
