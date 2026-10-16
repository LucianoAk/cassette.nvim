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

function MpvPlayer:sync_field(name)
	local function get_prop(prop_name)
		local res, err = self.connection:send({ command = { "get_property", prop_name } })

		if err then
			Logger.warn(
				MODULE_ORIGIN,
				"could not complete 'sync' request for '" .. prop_name .. "' of player, cause:\n" .. vim.inspect(err)
			)
			return nil
		end

		return res and res.data
	end

	if name == "path" then
		self.path = get_prop("path") or self.path
	elseif name == "media-title" then
		self.title = get_prop("media-title") or self.title
	elseif name == "video" then
		local val = get_prop("video")
		if val ~= nil then
			self.video = not not val
		end
	elseif name == "volume" then
		self.volume = get_prop("volume") or self.volume
	elseif name == "speed" then
		self.speed = get_prop("speed") or self.speed
	elseif name == "pause" then
		self.pause = not not get_prop("pause")
	elseif name == "playlist-pos" then
		self.playlist_pos = get_prop("playlist-pos") or self.playlist_pos
	elseif name == "playlist-count" then
		self.playlist_count = get_prop("playlist-count") or self.playlist_count
	elseif name == "time-pos" then
		self.time_pos = get_prop("time-pos") or self.time_pos
	elseif name == "duration" then
		self.duration = get_prop("duration") or self.duration
	end

	return self
end

function MpvPlayer:sync()
	local properties = {
		"path",
		"media-title",
		"video",
		"volume",
		"speed",
		"pause",
		"playlist-pos",
		"playlist-count",
		"time-pos",
		"duration",
	}

	for _, prop in ipairs(properties) do
		self:sync_field(prop)
	end

	return self
end

function MpvPlayer:load(path)
	local _, err = self.connection:send({ command = { "loadfile", path } })

	if err then
		Logger.warn(MODULE_ORIGIN, "could not complete 'load' request to player, cause:\n" .. err)
		return self
	end

	return self
end

function MpvPlayer:stop()
	local _, err = self.connection:send({ command = { "stop" } })

	if err then
		Logger.warn(MODULE_ORIGIN, "could not complete 'stop' request to player, cause:\n" .. err)
		return self
	end

	return self
end

function MpvPlayer:seek(time)
	local _, err = self.connection:send({ command = { "seek", time } })

	if err then
		Logger.warn(MODULE_ORIGIN, "could not complete 'seek' request to player, cause:\n" .. err)
		return self
	end

	return self
end

function MpvPlayer:next()
	if self.playlist_pos >= self.playlist_count then
		Logger.warn(MODULE_ORIGIN, "End of playlist reached")
		return self
	end

	local _, err = self.connection:send({ command = { "playlist-next" } })

	if err then
		Logger.warn(MODULE_ORIGIN, "could not complete 'seek' request to player, cause:\n" .. err)
		return self
	end

	return self
end

function MpvPlayer:previous()
	if self.playlist_pos <= 1 then
		Logger.warn(MODULE_ORIGIN, "Beginning of playlist reached")
		return self
	end

	local _, err = self.connection:send({ command = { "playlist-prev" } })

	if err then
		Logger.warn(MODULE_ORIGIN, "could not complete 'previous' request to player, cause:\n" .. err)
		return self
	end

	return self
end

function MpvPlayer:toggle_playback()
	local _, err = self.connection:send({ command = { "cycle", "pause" } })

	if err then
		Logger.warn(MODULE_ORIGIN, "could not complete 'toggle_playback' request to player, cause:\n" .. err)
		return self
	end

	return self
end

return MpvPlayer
