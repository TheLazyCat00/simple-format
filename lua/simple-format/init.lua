local M = {}

function M.select_nodes_by_type_in_current_line(node_type)
	local bufnr = vim.api.nvim_get_current_buf()
	local ns_id = vim.api.nvim_create_namespace("node_type_selection")
	local row = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed

	-- Find all nodes of specified type in current line
	local matches = {}
	local parser = vim.treesitter.get_parser(bufnr)
	local tree = parser:parse()[1]
	local root = tree:root()

	-- Create a query for the specified node type
	local query_string = '((' .. node_type .. ') @node)'
	local query = vim.treesitter.query.parse(vim.bo.filetype, query_string)

	-- Only query within the current line's range
	for id, node in query:iter_captures(root, bufnr, row, row + 1) do
		local start_row, start_col, end_row, end_col = node:range()
		table.insert(matches, {start_row, start_col, end_row, end_col})
	end

	-- Add extmarks for matches on the current line
	if #matches > 0 then
		for _, range in ipairs(matches) do
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, range[1], range[2], {
				end_line = range[3],
				end_col = range[4],
				hl_group = "Search"
			})
		end
	end

	return matches
end

function M.get_tree_for_current_line()
	local bufnr = vim.api.nvim_get_current_buf()
	local row = vim.api.nvim_win_get_cursor(0)[1] - 1  -- 0-indexed

	local parser = vim.treesitter.get_parser(bufnr)
	local tree = parser:parse()[1]
	local root = tree:root()

	-- Create a range for just the current line
	local start_row = row
	local end_row = row + 1

	-- Get a node for just the current line
	local line_node = root:named_descendant_for_range(start_row, 0, end_row, 0)

	return line_node
end

-- Select all instances of a specific highlight group in current buffer
function M.select_by_highlight(highlight_group)
	local bufnr = vim.api.nvim_get_current_buf()
	local ns_id = vim.api.nvim_create_namespace("highlight_selection")

	-- Find all matching highlights
	local matches = {}
	local root = M.get_tree_for_current_line()

	local query = vim.treesitter.query.parse(vim.bo.filetype, '((identifier) @id (#eq? @id "'..highlight_group..'"))')

	for id, node in query:iter_captures(root, bufnr, 0, -1) do
		local start_row, start_col, end_row, end_col = node:range()
		table.insert(matches, {start_row, start_col, end_row, end_col})
	end

	-- Add extmarks or select the ranges
	if #matches > 0 then
		-- Use extmarks to highlight
		for _, range in ipairs(matches) do
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, range[1], range[2], {
				end_line = range[3],
				end_col = range[4],
				hl_group = "Search"
			})
		end
	end
end

-- Replace all instances of a specific highlight group
-- function M.replace_by_highlight(highlight_group, replacement)
-- 	local bufnr = vim.api.nvim_get_current_buf()
--
-- 	-- Find all matching highlights (similar to previous function)
-- 	local matches = {}
-- 	-- Populate matches array...
--
-- 	-- Reverse order to avoid offset issues when replacing
-- 	table.sort(matches, function(a, b) 
-- 		if a[1] == b[1] then
-- 			return a[2] > b[2]
-- 		end
-- 		return a[1] > b[1]
-- 	end)
--
-- 	-- Replace each match
-- 	for _, range in ipairs(matches) do
-- 		local start_row, start_col, end_row, end_col = unpack(range)
-- 		local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
--
-- 		-- Handle multi-line replacement
-- 		if start_row == end_row then
-- 			lines[1] = string.sub(lines[1], 1, start_col) .. replacement .. string.sub(lines[1], end_col + 1)
-- 		else
-- 			-- More complex multi-line replacement logic here
-- 		end
--
-- 		vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, lines)
-- 	end
-- end

function M.setup(opts)
	vim.api.nvim_create_user_command("Test", function ()
		M.select_nodes_by_type_in_current_line("Operator")
	end,{})
end

return M
