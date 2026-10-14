local MpvHandler = {}
MpvHandler.__index = MpvHandler

function MpvHandler.ipc_message(connection, msg)
	local event_map = {
		["file-loaded"] = { "SyncPlayerFields" },
		pause = { "SyncPlayerPause" },
	}

	if msg.request_id and connection._pending[msg.request_id] then
		local callback = connection._pending[msg.request_id]
		connection._pending[msg.request_id] = nil
		callback(msg)
		return
	end

	local trigger_events = event_map[msg.event] or event_map[msg.name]
	if trigger_events then
		vim.schedule(function()
			for _, event in ipairs(trigger_events) do
				vim.api.nvim_exec_autocmds("User", { pattern = event })
			end
		end)
	end
end

function MpvHandler.end_process(player, list, focus)
	if player == focus then
		focus = nil
	end
	for index, p in ipairs(list) do
		if p == player then
			os.remove(player.socket)
			table.remove(list, index)
		end
	end
end

return MpvHandler
