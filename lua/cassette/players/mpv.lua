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

return MpvPlayer
