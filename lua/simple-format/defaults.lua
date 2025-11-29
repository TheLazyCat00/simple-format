---@class Config
---@field injectionOpeningAnchor string
---@field injectionClosingAnchor string
---@field groupStart string
---@field groupEnd string

---@type Config
local defaults = {
	-- HACK: use uncommon characters as anchors
	injectionOpeningAnchor = "\226\160\128",
	injectionClosingAnchor = "\226\160\129",
	groupStart = "<",
	groupEnd = ">",
}
return defaults;
