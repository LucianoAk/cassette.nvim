local BasePlayer = require("cassette.players.base")

local MpvPlayer = {}
MpvPlayer.__index = MpvPlayer
setmetatable(MpvPlayer, { __index = BasePlayer })

function MpvPlayer.new(builder)
	local self = BasePlayer.new(builder)
	setmetatable(self, MpvPlayer)

	self.socket = builder._socket
	self.process = builder._process
	self.connection = builder._connection

	return self
end

return MpvPlayer
