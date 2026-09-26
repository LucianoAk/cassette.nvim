local ipc = {}

function ipc.connect(socket_path, on_message_cb)
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

function ipc.send(conn, cmd_table, timeout)
	if not conn or not conn.is_connected then
		return nil, "Not connected"
	end

	local client = conn._client
	if not client or client:is_closing() then
		return nil, "Client is closing"
	end

	conn._next_id = conn._next_id + 1
	local req_id = conn._next_id
	cmd_table.request_id = req_id

	local response = nil
	conn._pending[req_id] = function(res)
		response = res
	end

	local payload = vim.json.encode(cmd_table) .. "\n"
	client:write(payload)

	timeout = timeout or 1000
	local success, timed_out = vim.wait(timeout, function()
		return response ~= nil
	end, 10)

	if not success or timed_out then
		conn._pending[req_id] = nil -- Clean up dangling request
		return nil, "Request timed out"
	end

	if not response then
		vim.notify("MPV IPC Error: Received empty response", vim.log.levels.ERROR)
		return nil, "Empty response"
	end

	if response.error and response.error ~= "success" then
		return nil, response.error
	end

	return response.data
end

return ipc
