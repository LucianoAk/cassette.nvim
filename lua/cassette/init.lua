local cassette = {}

local player = require("cassette.player")
local ui = require("cassette.ui")
local config = require("cassette.config")
local autocmd = require("cassette.autocmd")

function cassette.setup(user_opts)
	config.setup(user_opts)
	player.setup(config.options.player)
	autocmd.setup({ persist = config.options.session.persist })

	if config.options.session.persist or config.options.session.persist == true then
		vim.schedule(function()
			vim.api.nvim_exec_autocmds("User", {
				pattern = "ReconnectSockets",
			})
		end)
	end
end

function cassette.startVideo(source)
	local videoPlayer = player.new(true, source)

	if not videoPlayer then
		vim.notify("Failed to start player: MPV player could not be initialized.", vim.log.levels.ERROR)
		return
	end
end

function cassette.startMusic(source)
	local musicPlayer = player.new(false, source)

	if not musicPlayer then
		vim.notify("Failed to start player: MPV player could not be initialized.", vim.log.levels.ERROR)
		return
	end
end

function cassette.load(source)
	if not player.focus then
		vim.notify("Operation 'load' cannot be completed because no player is focused", vim.log.levels.WARN)
		return
	end
	player.focus:load(source)
end

function cassette.stop()
	if not player.focus then
		vim.notify("Operation 'stop' cannot be completed because no player is focused", vim.log.levels.WARN)
		return
	end
	player.focus:stop()
end

function cassette.seek(time)
	player.focus:seek(time)
end

function cassette.next()
	if player.focus.playlist_pos >= player.focus.playlist_count then
		vim.notify("End of playlist reached", vim.log.levels.WARN)
		return
	end
	player.focus:next()
end

function cassette.previous()
	if player.focus.playlist_pos <= 1 then
		vim.notify("Beginning of playlist reached", vim.log.levels.WARN)
		return
	end
	player.focus:previous()
end

function cassette.focus()
	if not player.running_players or #player.running_players == 0 then
		vim.notify("Operation 'focus' cannot be completed because there are no running players", vim.log.levels.WARN)
		return
	end
	ui.show_player_picker(player.running_players, function(p)
		return string.format("▶ Player: %s", p.title or "")
	end, function(choice)
		if choice then
			player.change_focus(choice)
			ui.updateCache(choice.title, choice.path, choice.playlist_pos, choice.playlist_count)
			return
		end
	end)
end

function cassette.getUIStatusLine()
	return ui.getStatusLine()
end

return cassette
