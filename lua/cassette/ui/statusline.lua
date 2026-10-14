local PlayerManager = require("cassette.players.manager")

local statusline = {}

statusline.cache = {}

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
function statusline.getStatusLine()
	if statusline.cache.playlist_count and statusline.cache.playlist_count > 1 then
		return string.format(
			"%s Playing: [ %s ] %d/%d",
			_getPlatformIcon(statusline.cache.path),
			statusline.cache.mediaTitle,
			statusline.cache.playlist_pos + 1,
			statusline.cache.playlist_count
		)
	end
	return string.format(
		"%s Playing: [ %s ]",
		_getPlatformIcon(statusline.cache.path or ""),
		statusline.cache.mediaTitle or ""
	)
end

function statusline.updateCache()
	statusline.cache = {
		mediaTitle = PlayerManager.focus.title or "?",
		path = PlayerManager.focus.path or "?",
		playlist_pos = PlayerManager.focus.playlist_pos or "?",
		playlist_count = PlayerManager.focus.playlist_count or "?",
	}
end

function statusline.cleanCache()
	statusline.cache = {
		mediaTitle = "",
		path = "",
		playlist_pos = 0,
		playlist_count = 0,
	}
end

return statusline
