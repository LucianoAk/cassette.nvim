local CassetteLogger = {}
CassetteLogger.__index = CassetteLogger

local LOG_TITLE = "Casstte"

function CassetteLogger.build_err(origin, message)
	return {
		origin = origin,
		message = message,
	}
end

function CassetteLogger.error(origin, message)
	vim.notify(origin .. ": " .. message, vim.log.levels.ERROR, { title = LOG_TITLE })
end

function CassetteLogger.warn(origin, message)
	vim.notify(origin .. ": " .. message, vim.log.levels.WARN, { title = LOG_TITLE })
end

function CassetteLogger.info(origin, message)
	vim.notify(origin .. ": " .. message, vim.log.levels.INFO, { title = LOG_TITLE })
end

return CassetteLogger
