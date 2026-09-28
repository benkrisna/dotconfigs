local M = {}

-- Lua pattern: "%%%%" matches a literal "%%"
local MARKER = "^# %%%%"

function M.bounds()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local s, e = 1, #lines
  for i = cur, 1, -1 do
    if lines[i]:match(MARKER) then s = i + 1; break end
  end
  for i = cur + 1, #lines do
    if lines[i]:match(MARKER) then e = i - 1; break end
  end
  return s, e
end

function M.run_cell(advance)
  local s, e = M.bounds()
  if e < s then return end
  vim.fn.MoltenEvaluateRange(s, e)
  if advance then
    local target = math.min(e + 2, vim.api.nvim_buf_line_count(0))
    vim.api.nvim_win_set_cursor(0, { target, 0 })
  end
end

function M.jump(dir)
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local i = cur + dir
  while i >= 1 and i <= #lines do
    if lines[i]:match(MARKER) then
      vim.api.nvim_win_set_cursor(0, { i, 0 }); return
    end
    i = i + dir
  end
end

function M.highlight()
  vim.cmd([[highlight default CellMarker guibg=NONE gui=underline]])
  local ns = vim.api.nvim_create_namespace("cell_markers")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:match(MARKER) then
      vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, { end_col = #line, hl_group = "CellMarker" })
    end
  end
end

return M
