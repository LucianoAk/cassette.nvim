local connector = {}

function connector.connect(socket_path, on_message_cb)
	local client = vim.uv.new_pipe(false)
	if not client then
		return nil
	end

	local connection = {
		_client = client,
		is_connected = false,
		_next_id = 0,
		_pending = {},
		close = function(self)
			if self._client and not self._client:is_closing() then
				self._client:close()
			end
		end,
	}

	client:connect(socket_path, function(err)
		if err then
			vim.notify("MPV IPC Connection Error: " .. tostring(err), vim.log.levels.ERROR)
			if not client:is_closing() then
				client:close()
			end
			return
		end

		connection.is_connected = true

		client:read_start(function(read_err, chunk)
			if read_err then
				vim.notify("MPV IPC Read Error: " .. tostring(read_err), vim.log.levels.WARN)
				if not client:is_closing() then
					client:close()
				end
				return
			end

			if chunk then
				for line in chunk:gmatch("[^\r\n]+") do
					local ok, msg = pcall(vim.json.decode, line)
					if ok and msg then
						if msg.request_id and connection._pending[msg.request_id] then
							local callback = connection._pending[msg.request_id]
							connection._pending[msg.request_id] = nil
							callback(msg)
						elseif on_message_cb then
							on_message_cb(msg)
						end
					end
				end
			else
				connection.is_connected = false
				if not client:is_closing() then
					client:close()
				end
			end
		end)
	end)

	return connection
end

function connector.send(connection, cmd_table, timeout)
	if not connection or not connection.is_connected then
		vim.notify("MPV IPC Error: Not connected", vim.log.levels.ERROR)
		return nil, "Not connected"
	end

	local client = connection._client
	if not client or client:is_closing() then
		vim.notify("MPV IPC Error: Client is closing", vim.log.levels.ERROR)
		return nil, "Client is closing"
	end

	connection._next_id = connection._next_id + 1
	local req_id = connection._next_id
	cmd_table.request_id = req_id

	local response = nil
	connection._pending[req_id] = function(res)
		response = res
	end

	local payload = vim.json.encode(cmd_table) .. "\n"
	client:write(payload)

	timeout = timeout or 1000
	local success, timed_out = vim.wait(timeout, function()
		return response ~= nil
	end, 10)

	if not success or timed_out then
		connection._pending[req_id] = nil
		vim.notify("MPV IPC Error: Request timed out", vim.log.levels.ERROR)
		return nil, "Request timed out"
	end

	if not response then
		vim.notify("MPV IPC Error: Received empty response", vim.log.levels.ERROR)
		return nil, "Empty response"
	end

	if response.error and response.error ~= "success" then
		vim.notify("MPV IPC Error: " .. response.error, vim.log.levels.ERROR)
		return nil, response.error
	end

	return response
end

function connector.ping(socket_path, timeout)
	timeout = timeout or 1000
	local client = vim.uv.new_pipe(false)
	if not client then
		return false, "Failed to create pipe"
	end

	local connected = false
	local response_data = nil

	client:connect(socket_path, function(err)
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

	local success, timed_out = vim.wait(timeout, function()
		return response_data ~= nil or (not connected and client:is_closing() == true)
	end, 10)

	if not client:is_closing() then
		client:close()
	end

	if not success or timed_out then
		return false, "Connection or request timed out"
	end

	if not response_data then
		return false, "No response received from socket"
	end

	local ok, decoded = pcall(vim.json.decode, response_data)
	if ok then
		return true, decoded
	end

	return true, response_data
end
return connector
