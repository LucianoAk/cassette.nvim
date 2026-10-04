<div align="center">

  # cassette.nvim

  [![Status](https://img.shields.io/badge/status-in_development-yellow)](https://github.com/LucianoAk/cassette.nvim/commits/main)
  ![GitHub last commit](https://img.shields.io/github/last-commit/LucianoAk/cassette.nvim)
  [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

</div>

A media player for Neovim that allows for playing video or music from local files or URLs

## Requirements
- mpv
- yt-dlp

## Configurations
```lua
{
	player = {
		default_volume = 100,
		default_speed = 1.0,
		socket_path = "/tmp/",
		socket_name_template = "mpv-socket-%nanoid",
	},
	session = {
		persist = true,
		reconnect_mode = "auto-reconnect", -- 'auto-reconnect', 'ask-each', 'ask-all'
	}
}
```
