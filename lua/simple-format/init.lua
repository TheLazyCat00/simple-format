local defaults = require("simple-format.defaults")
local M = {}

local opening_anchor
local closing_anchor
local group_start
local group_end

function M.get_hl_nodes(bufnr)
	local ft = vim.bo.filetype

	local status, parser = pcall(vim.treesitter.get_parser, bufnr, ft)
	if not status then
		return {}
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	local status, query = pcall(vim.treesitter.query.get, ft, "highlights")

	if not status then
		return {}
	end

	local operator_nodes = {}
	-- get current line (0-indexed)
	local current_line = vim.fn.line('.') - 1

	-- iterate captures only on the current line
	for id, node, _ in query:iter_captures(root, bufnr, current_line, current_line + 1) do
		local capture_name = query.captures[id]
		table.insert(
			operator_nodes,
			{capture_name, node}
		)
	end

	return operator_nodes
end


local function get_labeled_line(line, groups, bufnr)
	local nodes = M.get_hl_nodes(bufnr)
	local original_values = {}
	local offset = 0
	local index = 0

	for _, data in ipairs(nodes) do
		local name = data[1]
		local node = data[2]

		if not groups[name] then
			goto continue
		end
		index = index + 1

		local start_row, start_col, end_row, end_col = node:range()
		local node_text = vim.treesitter.get_node_text(node, 0)
		original_values[index] = node_text

		local start = start_col + offset
		local ending = end_col + offset

		local before = line:sub(1, start)
		local after = line:sub(ending + 1)

		local label = name .. index
		local replacement = opening_anchor .. label .. closing_anchor
		line = before .. replacement .. after

		local length_replacement = #replacement - #node_text
		offset = offset + length_replacement

		::continue::
	end

	return line, original_values
end

function M.replace(search, replace)
	local bufnr = vim.api.nvim_get_current_buf()
	local group_pattern = group_start .. "(.-)" .. group_end

	local groups = {}

	for match in search:gmatch(group_pattern) do
		groups[match] = true
	end

	local current_line = vim.fn.getline(".")
	local current_linenr = vim.fn.line('.')

	local labled_line, original_values = get_labeled_line(current_line, groups, bufnr)

	local modified_regex = search:gsub(group_start, opening_anchor):gsub(group_end, [[%%d]] .. closing_anchor)
	local processed_line = labled_line:gsub(modified_regex, replace)

	local labels_pattern = opening_anchor .. [[.-(%d-)]] .. closing_anchor
	local result = processed_line:gsub(labels_pattern, function(n)
		return original_values[tonumber(n)] or ""
	end)

	vim.api.nvim_buf_set_lines(
		bufnr,
		current_linenr - 1,
		current_linenr,
		false,
		{ result }
	)
end

function M.setup(opts)
	opening_anchor = opts.opening_anchor or defaults.opening_anchor
	closing_anchor = opts.closing_anchor or defaults.closing_anchor
	group_start = opts.group_start or defaults.group_start
	group_end = opts.group_end or defaults.group_end
end

M.setup({})

return M
