local Popup = {}

function Popup.show_player_picker(list, formatter, on_select)
	vim.ui.select(list, {
		prompt = "Select a Player:",
		format_item = formatter,
	}, function(choice, index)
		if on_select then
			on_select(choice, index)
		end
	end)
end

function Popup.ask_reconnect_socket(prompt, on_select)
	vim.ui.select({ "Yes", "No" }, {
		prompt = prompt,
	}, function(choice)
		on_select(choice == "Yes")
	end)
end

return Popup
