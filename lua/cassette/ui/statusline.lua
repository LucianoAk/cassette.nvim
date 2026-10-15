local PlayerManager = require("cassette.players.manager")

local Statusline = {}

Statusline.opts = {}

function Statusline.setup(statusline_configs)
	Statusline.opts = statusline_configs or {}
end

local function _getPlatformIcon(url)
	if PlayerManager.focus.pause and PlayerManager.focus.pause == true then
		return "󰏤"
	elseif url:match("youtube%.com") or url:match("youtu%.be") then
		return "󰗃"
	elseif url:match("twitch%.tv") then
		return "󰕃"
	elseif url:match("spotify%.com") then
		return "󰓇"
	else
		return "▶"
	end
end

-- TODO:
-- create a ui configuration to define the structure of the status line using a sections table
-- add duration section by taking the time-pos property, adding to it every second and syncing every 30 second
function Statusline.get()
	if Statusline.opts.hide_no_players and PlayerManager.length() == 0 then
		return ""
	end

	local player = PlayerManager.focus
	if player and player.playlist_count and player.playlist_count > 1 then
		return string.format(
			"%s Playing: [ %s ] %d/%d",
			_getPlatformIcon(player.path),
			player.title,
			player.playlist_pos + 1,
			player.playlist_count
		)
	end
	return string.format("%s Playing: [ %s ]", _getPlatformIcon(player.path or ""), player.title or "")
end

return Statusline
