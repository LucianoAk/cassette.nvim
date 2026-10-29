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
	ui = {
		statusline = {
      -- when no player are running statusline will be hidden if this option is 'true'
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
					type = "time",
					format = "<%s/%s>",
					separator = ":",
					sync_cycle = 10,
				},
				{
					type = "playlist",
					format = "%d of %d",
					fallback = 0,
					condition = function(d)
						return d.playlist_count and d.playlist_count > 1 or false
					end,
				},
			},
		},
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
- [mpv](https://github.com/mpv-player/mpv): Described as a free (as in freedom) media player for the command line.
- [yt-dlp](https://github.com/yt-dlp/yt-dlp): Described as a feature-rich command-line audio/video downloader with support for thousands of sites.

## License

This project is distributed under the MIT License. See [LICENSE](./LICENSE) for more information.
