local ui = {}

local player = require("cassette.player")

local function getPlatformIcon(url)
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
	local mediaTitle = player:getTitle()
	if not mediaTitle or mediaTitle == "" or mediaTitle == vim.NIL then
		return ""
	end

	local icon = getPlatformIcon(player.focus:getProperty("path"))

	local result = string.format("%s %s ", icon, mediaTitle)
	return result
end

return ui
