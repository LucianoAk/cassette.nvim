local BasePlayer = {}
BasePlayer.__index = BasePlayer

function BasePlayer.new(builder)
	local self = setmetatable({}, BasePlayer)

	self.path = builder._path
	self.video = builder._video
	self.volume = builder._volume
	self.speed = builder._speed
	self.pause = builder._pause
	self.title = builder._title
	self.playlist_pos = builder._playlist_pos
	self.playlist_count = builder._playlist_count

	return self
end

return BasePlayer
