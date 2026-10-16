local config = {}

config.defaults = {
	player = {
		default_volume = 100,
		default_speed = 1.0,
		socket_path = "/tmp/",
		socket_name_template = "mpv-socket-%nanoid",
	},
	ui = {
		statusline = {
			hide_no_players = true,
			section_separator = " ",
			sections = {
				{
					type = "icon",
					format = "%s", -- if not specified it will just insert the data
					property = "path", -- define the data that will be used for the check
					patterns = { -- order gives priority
						{
							match = ".*",
							icon = "󰏤",
							condition = function(d)
								return d.pause == true
							end,
						},
						{ match = "youtube%.com", icon = "󰗃" },
						{ match = "youtu%.be", icon = "󰗃" },
						{ match = "twitch%.tv", icon = "󰕃" },
						{ match = ".*", icon = "▶" },
					},
				},
				{
					type = "text",
					value = "Playing: ",
				},
				{
					type = "title",
					format = "[ %s ]", -- Template string wrapping the title (uses %s). If omitted, inserts text directly
					max_length = -1, -- Max visible characters. Negative turns it off
					indicator = { before = "...", after = "..." }, -- Strings attached to edges when text is clipped or scrolling
					scroll_speed = 0, -- Timer interval in ms. 0 turns off scrolling
					jump = 1, -- Number of characters skipped per tick. Positive scrolls forward, negative scrolls backward
					spacer = " | ", -- Transition bridge string used when the marquee loops from the end back to the start
				},
				{
					type = "playlist",
					format = "%d of %d",
					fallback = 0,
					condition = function(d)
						return d.playlist_count and d.playlist_count > 1 or false
					end,
				},
				{
					type = "time",
					format = "%s/%s",
					separator = ":",
					sync_cycle = 10,
				},
			},
		},
	},
	session = {
		persist = true,
		reconnect_mode = "auto-reconnect",
	},
}

config.options = vim.deepcopy(config.defaults)

function config.setup(user_opts)
	config.options = vim.tbl_deep_extend("force", config.defaults, user_opts or {})
	return config.options
end

return config
