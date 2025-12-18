local defaults = require("simple-format.defaults")

---@type Config
local config
local M = {}

---@param opts Config
function M.setup(opts)
	config = vim.tbl_deep_extend("force", defaults, opts)
end

---@class Node
---@field node TSNode
---@field name string
	
---@return Node[]
local function getCurrentLineNodes()
	local ft = vim.bo.filetype
	local currentLine = vim.fn.line(".") - 1 -- top most line = 0

	local parser_name = vim.treesitter.language.get_lang(ft)
	local status, parser = pcall(vim.treesitter.get_parser, 0, parser_name)
	if not status then
		return {}
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	local status, query = pcall(vim.treesitter.query.get, parser_name, "highlights")
	if not status then
		return {}
	end

	---@type Node[]
	local nodes = {}

	for id, node, _ in query:iter_captures(root, 0, currentLine, currentLine + 1) do
		if node:child_count() == 0 then
			local captureName = query.captures[id]
			table.insert(nodes, {
				name = captureName,
				node = node
			})
		end
	end

	return nodes
end

---@generic T
---@param list T[]
---@param callback fun(item: T): any
---@return T[][]
local function groupByField(list, callback)
	local groups = {}
	local order = {}
	
	for _, item in ipairs(list) do
		local key = callback(item)
		if not groups[key] then
		groups[key] = {}
		table.insert(order, key)
		end
		table.insert(groups[key], item)
	end
	
	local result = {}
	for _, key in ipairs(order) do
		table.insert(result, groups[key])
	end
	
	return result
end

---@generic T
---@param tbl T[]
---@return T[]
local function reverse(tbl)
	local reversed = {}
	for i = #tbl, 1, -1 do
		table.insert(reversed, tbl[i])
	end
	return reversed
end

---@return string
---@param nodes Node[]
---@param reveal boolean
local function getFillerStringFromNodes(nodes, reveal)
	local nodeText = vim.treesitter.get_node_text(nodes[1].node, 0)
	local fillerString = ""
	fillerString = fillerString .. "|"

	for _, node in ipairs(nodes) do
		fillerString = fillerString .. node.name .. "|"
	end

	fillerString = fillerString .. "=" .. nodeText
	local startAnchor = reveal and config.groupStart or config.injectionOpeningAnchor
	local endAnchor = reveal and config.groupEnd or config.injectionClosingAnchor
	fillerString = startAnchor .. fillerString .. endAnchor

	return fillerString
end

---@return string
---@param originalLine string
---@param nodes Node[]
---@param reveal boolean
local function injectNodesIntoLine(originalLine, nodes, reveal)
	local fillerString = getFillerStringFromNodes(nodes, reveal)
	local startRow, startCol, endRow, endCol = nodes[1].node:range()

	local stringBefore = originalLine:sub(1, startCol)
	local stringAfter = originalLine:sub(endCol + 1)

	local injectedLine = stringBefore .. fillerString .. stringAfter
	return injectedLine
end

---@return string
---@param reveal boolean
local function getInjectedLine(reveal)
	local currentLineContent = vim.api.nvim_get_current_line()
	local currentLineNodes = reverse(getCurrentLineNodes())
	local injectedLine = currentLineContent

	local groupedNodes = groupByField(currentLineNodes, function (node)
		local startRow, startCol, endRow, endCol = node.node:range()
		return startCol
	end)

	for _, nodes in ipairs(groupedNodes) do
		injectedLine = injectNodesIntoLine(injectedLine, nodes, reveal)
	end

	return injectedLine
end

---@return string
---@param regex string
---@param replaceGroups string
local function replace(regex, replaceGroups)
	local injectedLine = getInjectedLine(false)
	regex = regex:gsub(config.groupStart, config.injectionOpeningAnchor)
	regex = regex:gsub(config.groupEnd, config.injectionClosingAnchor)

	local lineTemplate = injectedLine:gsub(regex, replaceGroups)
	local nodeTextPattern = config.injectionOpeningAnchor .. [[.-=(.-)]] .. config.injectionClosingAnchor

	local result = lineTemplate:gsub(nodeTextPattern, function(text)
		return text or ""
	end)

	return result
end

---@param regex string
---@param replaceGroups string
function M.replace(regex, replaceGroups)
	local modfiedLine = replace(regex, replaceGroups)

	if modfiedLine == vim.fn.getline(".") then
		return
	end

	local currentLineNumber = vim.fn.line('.')
	pcall(function()
		vim.api.nvim_buf_set_lines(
			0,
			currentLineNumber - 1,
			currentLineNumber,
			false,
			{ modfiedLine }
		)
	end)
end

function M.reveal()
	local injectedLine = getInjectedLine(true)
	vim.notify(injectedLine, vim.log.levels.INFO)
end

return M
