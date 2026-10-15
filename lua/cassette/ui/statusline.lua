local PlayerManager = require("cassette.players.manager")
local Logger = require("cassette.utils.logger")

local Statusline = {}

Statusline.opts = {}

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

-- TODO:
-- create a ui configuration to define the structure of the status line using a sections table
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
		end
	end

	return table.concat(result_parts, Statusline.opts.section_separator or "")
end

return Statusline
