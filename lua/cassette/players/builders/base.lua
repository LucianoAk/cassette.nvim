local PlayerBuilder = {}
PlayerBuilder.__index = PlayerBuilder

PlayerBuilder.opts = {}

function PlayerBuilder.setup(player_configs)
	PlayerBuilder.opts = player_configs
end
function PlayerBuilder.new()
	local self = setmetatable({}, PlayerBuilder)

	self._path = ""
	self._video = true
	self._volume = PlayerBuilder.opts.default_volume or 100
	self._speed = PlayerBuilder.opts.default_speed or 1.0
	self._pause = false
	self._title = ""
	self._playlist_pos = -1
	self._playlist_count = 0

	return self
end

function PlayerBuilder:path(path)
	self._path = path
	return self
end

function PlayerBuilder:video(video)
	self._video = video
	return self
end

function PlayerBuilder:volume(volume)
	self._volume = volume
	return self
end

function PlayerBuilder:speed(speed)
	self._speed = speed
	return self
end

function PlayerBuilder:pause(pause)
	self._pause = pause
	return self
end

function PlayerBuilder:title(title)
	self._title = title
	return self
end

function PlayerBuilder:playlist_pos(playlist_pos)
	self._playlist_pos = playlist_pos
	return self
end

function PlayerBuilder:playlist_count(playlist_count)
	self._playlist_count = playlist_count
	return self
end

function PlayerBuilder:build()
	return require("cassette.players.base").new(self)
end

return PlayerBuilder
