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
