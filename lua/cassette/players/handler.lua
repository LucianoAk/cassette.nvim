local MpvHandler = {}
MpvHandler.__index = MpvHandler

function MpvHandler.ipc_message(connection, msg)
	local event_map = {
		["end-file"] = "CleanUICache",
		["file-loaded"] = "UpdateUICache",
		path = "UpdateUICache",
		["playlist-pos"] = "UpdateUICache",
		pause = "UpdatePlayerStatus",
	}

	if msg.request_id and connection._pending[msg.request_id] then
		local callback = connection._pending[msg.request_id]
		connection._pending[msg.request_id] = nil
		callback(msg)
		return
	end

	local trigger_event = event_map[msg.event] or event_map[msg.name]
	if trigger_event then
		vim.schedule(function()
			vim.api.nvim_exec_autocmds("User", { pattern = trigger_event })
		end)
	end
end

function MpvHandler.end_process(player, list)
	for index, p in ipairs(list) do
		if p == player then
			os.remove(player.socket)
			table.remove(list, index)
		end
	end
end

return MpvHandler
