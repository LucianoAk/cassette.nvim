local PlayerManager = require("cassette.players.manager")
local Logger = require("cassette.utils.logger")
local Executor = require("cassette.utils.executor")

local Statusline = {}

Statusline.opts = {}
local timer = {
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

		if property:match(match) and (not pattern.condition or pattern.condition(data)) then
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

		local text_timer = timer.text[title]
		if not text_timer then
			text_timer = {
				offset = jump < 0 and plen or 1,
			}
			text_timer.handle = vim.uv.new_timer()
			text_timer.handle:start(
				0,
				math.abs(scroll_speed),
				vim.schedule_wrap(function()
					if #title > max_length then
						text_timer.offset = ((text_timer.offset + jump - 1) % plen) + 1
						vim.cmd.redrawstatus()
					end
				end)
			)
			local _, err = Executor.watch_pid(data.process.pid, function()
				text_timer.handle:stop()
				text_timer.handle:close()
				text_timer.handle = nil
			end)

			if err then
				Logger.build_err(err.origin, err.message)
			end

			timer.text[title] = text_timer
		end

		local offset = text_timer.offset
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
	return string.format(format, data.playlist_pos + 1, data.playlist_count)
end

local function _render_time(section, data)
	local id, cycle = data.id, section.sync_cycle

	local time_timer = timer.time[id]
	if not time_timer then
		time_timer = {
			sync_counter = 0,
			last_duration = nil,
			dur_hours = 0,
			dur_minutes = 0,
			dur_secs = 0,
		}
		timer.time[id] = time_timer
	end

	time_timer.data = data

	if not data.time_pos or time_timer.sync_counter >= cycle then
		time_timer.sync_counter = 0
		vim.api.nvim_exec_autocmds("User", { pattern = "SyncPlayerTime", data = { player_id = id } })
	end

	if not time_timer.handle then
		time_timer.handle = vim.uv.new_timer()
		if not time_timer.handle then
			Logger.warn(MODULE_ORIGIN, "could not render 'time' section, no sync timer could not be created")
			return ""
		end

		time_timer.handle:start(
			1000,
			1000,
			vim.schedule_wrap(function()
				local active_data = time_timer.data
				if active_data and not active_data.pause and type(active_data.time_pos) == "number" then
					active_data.time_pos = active_data.time_pos + 1
				end
				time_timer.sync_counter = time_timer.sync_counter + 1
				vim.cmd.redrawstatus()
			end)
		)
		local _, err = Executor.watch_pid(data.process.pid, function()
			time_timer.handle:stop()
			time_timer.handle:close()
			time_timer.handle = nil
		end)

		if err then
			Logger.build_err(err.origin, err.message)
		end
	end

	local pos = data.time_pos
	local sep, fmt = section.separator, section.format
	local th, tm, ts = math.floor(pos / 3600), math.floor((pos % 3600) / 60), math.floor(pos % 60)

	local dur = data.duration or 0
	if dur ~= time_timer.last_duration then
		time_timer.last_duration = dur
		time_timer.dur_hours = math.floor(dur / 3600)
		time_timer.dur_minutes = math.floor((dur % 3600) / 60)
		time_timer.dur_secs = math.floor(dur % 60)
	end

	local t_str, d_str
	if th > 0 or time_timer.dur_hours > 0 then
		t_str = string.format("%d%s%02d%s%02d", th, sep, tm, sep, ts)
		d_str =
			string.format("%d%s%02d%s%02d", time_timer.dur_hours, sep, time_timer.dur_minutes, sep, time_timer.dur_secs)
	else
		t_str = string.format("%02d%s%02d", tm, sep, ts)
		d_str = string.format("%02d%s%02d", time_timer.dur_minutes, sep, time_timer.dur_secs)
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
