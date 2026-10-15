local MpvHandler = {}
MpvHandler.__index = MpvHandler

function MpvHandler.ipc_message(connection, msg, id)
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
				vim.api.nvim_exec_autocmds("User", { pattern = event, data = { player_id = id } })
			end
		end)
	end
end

function MpvHandler.end_process(player, list, focus)
	if player == focus then
		focus = nil
	end
	list[player.id] = nil
end

return MpvHandler
