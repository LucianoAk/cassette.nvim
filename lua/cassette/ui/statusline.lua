local PlayerManager = require("cassette.players.manager")

local Statusline = {}

Statusline.cache = {}

local function _getPlatformIcon(url)
	if url:match("youtube%.com") or url:match("youtu%.be") then
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
-- add configuration for ui status line where if false it doesn't update status line
-- add configuration for ui status line where if false the status line dissapears when no player in foucs
-- update ui on pause property change to make icon 󰏤, 󰏥, 󰏧 or 󰏦
function Statusline.getStatusLine()
	if Statusline.cache.playlist_count and Statusline.cache.playlist_count > 1 then
		return string.format(
			"%s Playing: [ %s ] %d/%d",
			_getPlatformIcon(Statusline.cache.path),
			Statusline.cache.mediaTitle,
			Statusline.cache.playlist_pos + 1,
			Statusline.cache.playlist_count
		)
	end
	return string.format(
		"%s Playing: [ %s ]",
		_getPlatformIcon(Statusline.cache.path or ""),
		Statusline.cache.mediaTitle or ""
	)
end

function Statusline.updateCache()
	Statusline.cache = {
		mediaTitle = PlayerManager.focus.title or "?",
		path = PlayerManager.focus.path or "?",
		playlist_pos = PlayerManager.focus.playlist_pos or "?",
		playlist_count = PlayerManager.focus.playlist_count or "?",
	}
end

function Statusline.cleanCache()
	Statusline.cache = {
		mediaTitle = "",
		path = "",
		playlist_pos = 0,
		playlist_count = 0,
	}
end

return Statusline
