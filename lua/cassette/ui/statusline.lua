local PlayerManager = require("cassette.players.manager")
local Logger = require("cassette.utils.logger")

local Statusline = {}

Statusline.opts = {}
Statusline.timer = {
	text = {},
	time = {},
}

local MODULE_ORIGIN = "Status Line"

function Statusline.setup(statusline_configs)
	Statusline.opts = statusline_configs or {}
end

local function _render_icon(section, data)
	local property = data[section.property] or " "
	local format = section.format
	local patterns = section.patterns

	if not property then
		Logger.warn(MODULE_ORIGIN, "could not render 'icon' section, no property data specified")
		return
	end

	for _, pattern in ipairs(patterns) do
		local match = pattern.match
		local icon = pattern.icon
		local condition = pattern.condition or function(d)
			return true
		end

		if property:match(match) and condition(data) then
			if format then
				return string.format(format, icon)
			end
			return icon
		end
	end
end

local function _render_text(section)
	local value = section.value
	if not value then
		Logger.warn(MODULE_ORIGIN, "could not render 'text' section, no property data specified")
		return ""
	end
	return value
end

local offsets = {}

local function _render_title(section, data)
	local title = data.title or ""
	local max_length = section.max_length or #title
	local format = section.format

	if max_length < 0 then
		return format and string.format(format, title) or title
	end

	local ind = section.indicator or {}
	local before, after = ind.before or "", ind.after or ""
	local scroll_speed = section.scroll_speed or 0
	local jump = section.jump or 1
	local spacer = section.spacer or " "

	local result
	if #title <= max_length then
		result = title
	elseif scroll_speed == 0 then
		result = title:sub(1, max_length) .. after
	else
		local padded = title .. spacer
		local plen = #padded
		offsets[title] = offsets[title] or (jump < 0 and plen or 1)

		if not Statusline.timer.text[title] then
			Statusline.timer.text[title] = vim.uv.new_timer()
			Statusline.timer.text[title]:start(
				0,
				math.abs(scroll_speed),
				vim.schedule_wrap(function()
					if #title > max_length then
						offsets[title] = ((offsets[title] + jump - 1) % plen) + 1
						vim.cmd.redrawstatus()
					end
				end)
			)
		end

		local offset = offsets[title]
		if offset + max_length - 1 <= #title then
			result = title:sub(offset, offset + max_length - 1)
		else
			local p1 = title:sub(offset)
			local rem = max_length - #p1
			result = rem <= #spacer and (p1 .. spacer:sub(1, rem)) or (p1 .. spacer .. title:sub(1, rem - #spacer))
		end

		if before ~= "" then
			result = before .. result
		end
		if after ~= "" then
			result = result .. after
		end
	end

	return format and string.format(format, result) or result
end

local function _render_playlist(section, data)
	local format = section.format
	local pos = data.playlist_pos or section.fallback
	local count = data.playlist_count or section.fallback

	if not format then
		Logger.warn(MODULE_ORIGIN, "could not render 'playlist' section, no format configuration specified")
		return ""
	end
	if not pos or not count then
		Logger.warn(
			MODULE_ORIGIN,
			"could not render 'playlist' section, no property data specified or no fallback defined"
		)
		return ""
	end
	return string.format(format, data.playlist_pos, data.playlist_count)
end

local current_time_pos = {}
local sync_counter = {}
local last_duration = nil
local dur_hours, dur_minutes, dur_secs = 0, 0, 0

local function _render_time(section, data)
	local id, cycle = data.id, section.sync_cycle

	if not current_time_pos[id] or sync_counter[id] >= cycle then
		sync_counter[id] = 0
		vim.api.nvim_exec_autocmds("User", { pattern = "SyncPlayerTime", data = { player_id = id } })
		if type(data.time_pos) == "number" then
			current_time_pos[id] = data.time_pos
		end
	end

	local pos = current_time_pos[id] or 0
	current_time_pos[id] = pos

	if not Statusline.timer.time[id] then
		Statusline.timer.time[id] = vim.uv.new_timer()
		if not Statusline.timer.time[id] then
			Logger.warn(MODULE_ORIGIN, "could not render 'time' section, no sync timer could not be created")
			return ""
		end

		Statusline.timer.time[id]:start(
			1000,
			1000,
			vim.schedule_wrap(function()
				if not data.pause and type(current_time_pos[id]) == "number" then
					current_time_pos[id] = current_time_pos[id] + 1
				end
				sync_counter[id] = sync_counter[id] + 1
				vim.cmd.redrawstatus()
			end)
		)
	end

	local sep, fmt = section.separator, section.format
	local th, tm, ts = math.floor(pos / 3600), math.floor((pos % 3600) / 60), math.floor(pos % 60)

	local dur = data.duration or 0
	if dur ~= last_duration then
		last_duration, dur_hours, dur_minutes, dur_secs =
			dur, math.floor(dur / 3600), math.floor((dur % 3600) / 60), math.floor(dur % 60)
	end

	local t_str, d_str
	if th > 0 or dur_hours > 0 then
		t_str = string.format("%d%s%02d%s%02d", th, sep, tm, sep, ts)
		d_str = string.format("%d%s%02d%s%02d", dur_hours, sep, dur_minutes, sep, dur_secs)
	else
		t_str = string.format("%02d%s%02d", tm, sep, ts)
		d_str = string.format("%02d%s%02d", dur_minutes, sep, dur_secs)
	end

	return string.format(fmt, t_str, d_str)
end

function Statusline.get()
	if Statusline.opts.hide_no_players and PlayerManager.length() == 0 then
		return ""
	end

	local result_parts = {}
	local data = PlayerManager.focus or {}

	for _, section in ipairs(Statusline.opts.sections) do
		local type = section.type
		local condition = section.condition

		if not condition or condition(data) then
			if type == "icon" then
				table.insert(result_parts, _render_icon(section, data))
			elseif type == "text" then
				table.insert(result_parts, _render_text(section))
			elseif type == "title" then
				table.insert(result_parts, _render_title(section, data))
			elseif type == "playlist" then
				table.insert(result_parts, _render_playlist(section, data))
			elseif type == "time" then
				table.insert(result_parts, _render_time(section, data))
			end
		end
	end

	return table.concat(result_parts, Statusline.opts.section_separator or "")
end

return Statusline
