local Logger = require("cassette.utils.logger")

local IpcConnection = {}
IpcConnection.__index = IpcConnection

local MODULE_ORIGIN = "IPC Connection"

function IpcConnection.new(socket, on_message)
	local self = setmetatable({}, IpcConnection)

	local client = vim.uv.new_pipe(false)
	if not client then
		return nil, Logger.build_err(MODULE_ORIGIN, "Failed to create pipe")
	end

	self._client = client
	self.is_connected = false
	self._next_id = 0
	self._pending = {}

	client:connect(socket, function(err)
		if err then
			Logger.error(MODULE_ORIGIN, tostring(err))
			if not client:is_closing() then
				client:close()
			end
			return
		end

		self.is_connected = true

		client:read_start(function(read_err, chunk)
			if read_err then
				Logger.error(MODULE_ORIGIN, tostring(err))
				if not client:is_closing() then
					client:close()
				end
				return
			end

			if chunk then
				for line in chunk:gmatch("[^\r\n]+") do
					local ok, msg = pcall(vim.json.decode, line)
					if ok and msg then
						on_message(msg)
					end
				end
			else
				self.is_connected = false
				if not client:is_closing() then
					client:close()
				end
			end
		end)
	end)

	return self
end

function IpcConnection:send(command)
	if not self.is_connected then
		return nil, Logger.build_err(MODULE_ORIGIN, "Not connected")
	end

	if not self._client or self._client:is_closing() then
		return nil, Logger.build_err(MODULE_ORIGIN, "Client is closing")
	end
	self._next_id = self._next_id + 1
	local req_id = self._next_id
	command.request_id = req_id

	local response = nil
	self._pending[req_id] = function(res)
		response = res
	end

	local payload = vim.json.encode(command) .. "\n"
	self._client:write(payload)

	local success, timed_out = vim.wait(1000, function()
		return response ~= nil
	end, 10)

	if not success or timed_out then
		self._pending[req_id] = nil
		return nil, Logger.build_err(MODULE_ORIGIN, "Request timed out")
	end

	if not response then
		return nil, Logger.build_err(MODULE_ORIGIN, "Received empty response")
	end

	if response.error and response.error ~= "success" then
		return nil, Logger.build_err(MODULE_ORIGIN, response.error)
	end

	return response
end

function IpcConnection.ping(socket)
	local client = vim.uv.new_pipe(false)
	if not client then
		return nil, Logger.build_err(MODULE_ORIGIN, "Failed to create pipe")
	end

	local connected = false
	local response_data = nil

	client:connect(socket, function(err)
		if err then
			if not client:is_closing() then
				client:close()
			end
			return
		end

		connected = true

		client:read_start(function(read_err, chunk)
			if read_err or not chunk then
				if not client:is_closing() then
					client:close()
				end
				return
			end
			response_data = chunk
		end)

		local payload = vim.json.encode({ command = { "get_version" }, request_id = 0 }) .. "\n"
		client:write(payload)
	end)

	local success, timed_out = vim.wait(1000, function()
		return response_data ~= nil or (not connected and client:is_closing() == true)
	end, 10)

	if not client:is_closing() then
		client:close()
	end

	if not success or timed_out then
		return false, Logger.build_err(MODULE_ORIGIN, "Connection or request timed out")
	end

	if not response_data then
		return false, Logger.build_err(MODULE_ORIGIN, "No response received from socket")
	end

	local ok, decoded = pcall(vim.json.decode, response_data)
	if ok then
		return true, decoded
	end

	return true, response_data
end

function IpcConnection:close()
	if self._client and not self._client:is_closing() then
		self._client:close()
	end
end

return IpcConnection
