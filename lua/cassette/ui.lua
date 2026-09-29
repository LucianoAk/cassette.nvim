local ui = {}

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

function ui.updateCache(title, path)
	ui.cache = {
		mediaTitle = title,
		path = path,
	}
end

function ui.cleanCache()
	ui.cache = {
		mediaTitle = "",
		path = "",
	}
end

function ui.show_player_picker(list, formatter, on_select)
	vim.ui.select(list, {
		prompt = "Select a Player:",
		format_item = formatter,
	}, function(choice)
		if on_select then
			on_select(choice)
		end
		if choice and choice.title and choice.path then
			ui.updateCache(choice.title, choice.path)
		end
	end)
end

return ui
