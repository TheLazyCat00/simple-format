local defaults = require("simple-format.defaults")
local M = {}

local opening_anchor
local closing_anchor
local group_start
local group_end

function M.get_hl_nodes(bufnr, linenr, specific)
	local ft = vim.bo.filetype

	local parser_name = vim.treesitter.language.get_lang(ft)
	local status, parser = pcall(vim.treesitter.get_parser, bufnr, parser_name)
	if not status then
		return {}
	end

	local tree = parser:parse()[1]
	local root = tree:root()

	local status, query = pcall(vim.treesitter.query.get, parser_name, "highlights")
	if not status then
		return {}
	end

	local nodes = {}
	local place_nodes = {}
	linenr = linenr - 1

	-- iterate captures only on the current line
	for id, node, _ in query:iter_captures(root, bufnr, linenr, linenr + 1) do
		local start_row, start_col, end_row, end_col = node:range()
		local capture_name = query.captures[id]
		local key = start_col
		if place_nodes[key] then
			if specific then
				place_nodes[key].name = capture_name
				place_nodes[key].node = node
			end
		else
			place_nodes[key] = {
				name = capture_name,
				node = node
			}
		end
	end

	for _, data in pairs(place_nodes) do
		local name = data.name
		local node = data.node

		table.insert(
			nodes,
			{ name, node }
		)
	end

	table.sort(nodes, function(a, b)
		local _, a_node = a[1], a[2]
		local a_row, a_col = a_node:range()
		local _, b_node = b[1], b[2]
		local b_row, b_col = b_node:range()
		return a_col < b_col
	end)

	return nodes
end

local function get_labeled_line(line, linenr, groups, bufnr, specific)
	local nodes = M.get_hl_nodes(bufnr, linenr, specific)
	local offset = 0

	for _, data in ipairs(nodes) do
		local name = data[1]
		local node = data[2]

		if not groups[name] then
			goto continue
		end

		local start_row, start_col, end_row, end_col = node:range()
		local node_text = vim.treesitter.get_node_text(node, 0)

		local start = start_col + offset
		local ending = end_col + offset

		local before = line:sub(1, start)
		local after = line:sub(ending + 1)

		local label = name .. "=" .. node_text
		local replacement = opening_anchor .. label .. closing_anchor
		line = before .. replacement .. after

		local length_replacement = #replacement - #node_text
		offset = offset + length_replacement

		::continue::
	end

	return line
end

function M.replace(search, replace, specific)
	specific = specific or false
	local bufnr = vim.api.nvim_get_current_buf()
	local group_pattern = group_start .. "(.-)=.-" .. group_end

	local groups = {}

	for match in search:gmatch(group_pattern) do
		groups[match] = true
	end

	local current_line = vim.fn.getline(".")
	local current_linenr = vim.fn.line('.')

	local labled_line = get_labeled_line(current_line, current_linenr, groups, bufnr, specific)

	local modified_regex = search:gsub(group_start, opening_anchor):gsub(group_end, closing_anchor)
	local processed_line = labled_line:gsub(modified_regex, replace)

	local labels_pattern = opening_anchor .. [[.-=(.-)]] .. closing_anchor
	local result = processed_line:gsub(labels_pattern, function(text)
		return text or ""
	end)

	if result == current_line then
		return
	end

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

return M
