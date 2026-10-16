local PlayerManager = require("cassette.players.manager")
local Logger = require("cassette.utils.logger")

local Statusline = {}

Statusline.opts = {}

local MODULE_ORIGIN = "Status Line"

function Statusline.setup(statusline_configs)
	Statusline.opts = statusline_configs or {}
end

-- TODO: add support for condition config
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

-- TODO: add support for condition config
local function _render_text(section)
	local value = section.value
	if not value then
		Logger.warn(MODULE_ORIGIN, "could not render 'text' section, no property data specified")
		return ""
	end
	return value
end

local active_timers = {}
local offsets = {}

-- TODO: add support for condition config
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

		if not active_timers[title] then
			active_timers[title] = vim.uv.new_timer()
			active_timers[title]:start(
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

-- TODO:
-- add duration section by taking the time-pos property, adding to it every second and syncing every 30 second
function Statusline.get()
	if Statusline.opts.hide_no_players and PlayerManager.length() == 0 then
		return ""
	end

	local result_parts = {}
	local data = PlayerManager.focus or {}

	for _, section in ipairs(Statusline.opts.sections) do
		local type = section.type
		if type == "icon" then
			table.insert(result_parts, _render_icon(section, data))
		elseif type == "text" then
			table.insert(result_parts, _render_text(section))
		elseif type == "title" then
			table.insert(result_parts, _render_title(section, data))
		end
	end

	return table.concat(result_parts, Statusline.opts.section_separator or "")
end

return Statusline
