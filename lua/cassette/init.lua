local cassette = {}

local player = require("cassette.player")
local ui = require("cassette.ui")
local config = require("cassette.config")
local autocmd = require("cassette.autocmd")

function cassette.setup(user_opts)
	config.setup(user_opts)
	player.setup(config.options.player)
	autocmd.setup({ persist = config.options.player.persist })

	if config.options.player.persist or config.options.player.persist == true then
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

function cassette.focus()
	if not player.running_players or #player.running_players == 0 then
		vim.notify("Operation 'focus' cannot be completed because there are no running players", vim.log.levels.WARN)
		return
	end
	ui.show_player_picker(player.running_players, function(p)
		return string.format("▶ Player: %s", p.title or "")
	end, function(choice)
		player.change_focus(choice)
		ui.updateCache(choice.title, choice.path)
	end)
end

function cassette.getUIStatusLine()
	return ui.getStatusLine()
end

return cassette
