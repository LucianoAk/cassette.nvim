<div align="center">

  # 📼 cassette.nvim

  [![Status](https://img.shields.io/badge/status-in_development-yellow)](https://github.com/LucianoAk/cassette.nvim/commits/main)
  ![GitHub last commit](https://img.shields.io/github/last-commit/LucianoAk/cassette.nvim)
  [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)

</div>

A plugin that launches, manages, and controls media playback, allowing for you to play video or music from local files or URLs directly inside Neovim.

## Requirements
- mpv
- yt-dlp

_Note: support for other media players and extractors may be added later_

## Configurations
```lua
{
	player = {
		default_volume = 100,
		default_speed = 1.0,
		socket_path = "/tmp/",
    -- for the socket name template use any of the flags: '%uuid', '%nanoid', '%hrtime'
    -- if no flags are provided the plugin will append '-%hrtime' to the end of the provided string
		socket_name_template = "mpv-socket-%nanoid", -- '%uuid', '%nanoid', '%hrtime'
	},
	session = {
    -- if this is 'true' the plugin will not close any of the running players on exit, and will search for running players on start
		persist = true,
		reconnect_mode = "auto-reconnect", -- 'auto-reconnect', 'ask-each', 'ask-all'
	}
}
```

## Acknowledgments

This project relies on other projects' functionalities for its resources and features:
- [mpv](https://github.com/mpv-player/mpv): A free (as in freedom) media player for the command line.
- [yt-dlp](https://github.com/yt-dlp/yt-dlp): A feature-rich command-line audio/video downloader with support for thousands of sites.
