local config = {}

config.defaults = {
	player = {
		default_volume = 100,
		default_speed = 1.0,
		socket_path = "/tmp/",
		socket_name_template = "mpv-socket-%nanoid",
	},
	session = {
		persist = true,
	},
}

config.options = vim.deepcopy(config.defaults)

function config.setup(user_opts)
	config.options = vim.tbl_deep_extend("force", config.defaults, user_opts or {})
	return config.options
end

return config
