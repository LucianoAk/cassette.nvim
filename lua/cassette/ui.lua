local ui = {}

local player = require("cassette.player")

ui.cache = {}

local function _getPlatformIcon(url)
	if url:match("youtube%.com") or url:match("youtu%.be") then
		return "󰗃 "
	elseif url:match("twitch%.tv") then
		return "󰕃 "
	elseif url:match("spotify%.com") then
		return "󰓇 "
	else
		return "▶ "
	end
end

function ui.getStatusLine()
	return string.format("%s Playing: [ %s ]", _getPlatformIcon(ui.cache.path or ""), ui.cache.mediaTitle or "")
end

function ui.updateCache()
	ui.cache = {
		mediaTitle = player.focus:getTitle(),
		path = player.focus:getPath(),
	}
end

return ui
