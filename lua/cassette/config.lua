local config = {}

config.defaults = {
	player = {
		volume = 100,
		speed = 1.0,
		socketName = "mpv-%d-socket",
	},
}

config.options = vim.deepcopy(config.defaults)

function config.setup(user_opts)
	config.options = vim.tbl_deep_extend("force", config.defaults, user_opts or {})
	return config.options
end

return config
