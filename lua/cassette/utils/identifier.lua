local identifier = {}

local seed = os.time()
if vim.uv and vim.uv.hrtime then
	seed = seed + vim.uv.hrtime()
end
math.randomseed(seed)

function identifier.uuid()
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	return (
		string.gsub(template, "[xy]", function(c)
			local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
			return string.format("%x", v)
		end)
	)
end

function identifier.nanoid(size)
	size = size or 21
	local alphabet = "_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local alphabet_len = #alphabet

	local id = {}
	for i = 1, size do
		local rand_index = math.random(1, alphabet_len)
		id[i] = alphabet:sub(rand_index, rand_index)
	end

	return table.concat(id)
end

function identifier.hrtime()
	return vim.uv.hrtime()
end

return identifier
