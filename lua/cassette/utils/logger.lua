local Logger = {}
Logger.__index = Logger

local LOG_TITLE = "Casstte"

function Logger.build_err(origin, message)
	return {
		origin = origin,
		message = message,
	}
end

function Logger.error(origin, message)
	vim.notify(origin .. ": " .. message, vim.log.levels.ERROR, { title = LOG_TITLE })
end

function Logger.warn(origin, message)
	vim.notify(origin .. ": " .. message, vim.log.levels.WARN, { title = LOG_TITLE })
end

function Logger.info(origin, message)
	vim.notify(origin .. ": " .. message, vim.log.levels.INFO, { title = LOG_TITLE })
end

return Logger
