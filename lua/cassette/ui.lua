local ui = {}

ui.cache = {}

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
function ui.getStatusLine()
	if ui.cache.playlist_count and ui.cache.playlist_count > 1 then
		return string.format(
			"%s Playing: [ %s ] %d/%d",
			_getPlatformIcon(ui.cache.path or ""),
			ui.cache.mediaTitle or "",
			ui.cache.playlist_pos or 0,
			ui.cache.playlist_count or 0
		)
	end
	return string.format("%s Playing: [ %s ]", _getPlatformIcon(ui.cache.path or ""), ui.cache.mediaTitle or "")
end

function ui.updateCache(title, path, playlist_pos, playlist_count)
	ui.cache = {
		mediaTitle = title,
		path = path,
		playlist_pos = playlist_pos,
		playlist_count = playlist_count,
	}
end

function ui.cleanCache()
	ui.cache = {
		mediaTitle = "",
		path = "",
		playlist_pos = 0,
		playlist_count = 0,
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
	end)
end

function ui.ask_reconnect_socket(prompt, on_select)
	vim.ui.select({ "Yes", "No" }, {
		prompt = prompt,
	}, function(choice)
		on_select(choice == "Yes")
	end)
end

return ui
