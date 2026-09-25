local ui = {}

local player = require("cassette.player")

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
	local mediaTitle = player.focus:getTitle()
	if not mediaTitle or mediaTitle == "" or mediaTitle == vim.NIL then
		return ""
	end

	local icon = _getPlatformIcon(player.focus:getPath())

	local result = string.format("%s Playing: [ %s ]", icon, mediaTitle)
	return result
end

return ui
