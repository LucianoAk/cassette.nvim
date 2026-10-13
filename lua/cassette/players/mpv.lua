local BasePlayer = require("cassette.players.base")
local MpvBuilder = require("cassette.players.builders.mpv")
local Logger = require("cassette.utils.logger")

local MpvPlayer = {}
MpvPlayer.__index = MpvPlayer
setmetatable(MpvPlayer, { __index = BasePlayer })

local MODULE_ORIGIN = "Mpv Player"

function MpvPlayer.new(builder)
	local self = BasePlayer.new(builder)
	setmetatable(self, MpvPlayer)

	self.socket = builder._socket
	self.process = builder._process
	self.connection = builder._connection

	return self
end

function MpvPlayer.builder()
	return MpvBuilder.new()
end

function MpvPlayer:sync()
	local function get_prop(name)
		local res, err = self.connection:send({ command = { "get_property", name } })

		if err then
			Logger.warn(
				MODULE_ORIGIN,
				"could not complete 'sync' request for '" .. name .. "' of player, cause:\n" .. vim.inspect(err)
			)
			return nil
		end

		return res and res.data or nil
	end

	self.path = get_prop("path") or self.path
	self.title = get_prop("media-title") or self.title
	self.video = not not get_prop("video") or self.video
	self.volume = get_prop("volume") or self.volume
	self.speed = get_prop("speed") or self.speed
	self.pause = not not get_prop("pause") or self.pause
	self.playlist_pos = get_prop("playlist-pos") or self.playlist_pos
	self.playlist_count = get_prop("playlist-count") or self.playlist_count

	return self
end

return MpvPlayer
