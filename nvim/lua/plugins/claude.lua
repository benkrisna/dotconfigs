-- Resolve the pending Claude diff from any window (including the Claude terminal),
-- then land back in the editor. accept/deny only work with the cursor in the diff buffer.
local function resolve_diff(cmd)
  return function()
    local origin = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.b[buf].claudecode_diff_tab_name then
        vim.api.nvim_set_current_win(win)
        vim.cmd(cmd)
        -- the diff closes on resolve; if the origin was the terminal, go to the editor instead
        vim.schedule(function()
          if vim.bo[vim.api.nvim_get_current_buf()].buftype == "terminal" then
            vim.cmd("wincmd p")
          end
          vim.cmd("stopinsert")
        end)
        return
      end
    end
    vim.notify("No pending Claude diff", vim.log.levels.INFO)
    if vim.api.nvim_win_is_valid(origin) then vim.api.nvim_set_current_win(origin) end
  end
end

return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal_cmd = "/Users/benkris/.local/bin/claude",
  },
  config = function(_, opts)
    require("claudecode").setup(opts)
    -- claudecode reloads the buffer with `:edit` after a diff is accepted, which fires
    -- BufUnload, and molten-nvim kills the kernel on BufUnload. Suppress that event
    -- during the reload so the kernel (and its variables) survive.
    local diff = require("claudecode.diff")
    local orig = diff.reload_file_buffers_manual
    diff.reload_file_buffers_manual = function(...)
      local saved = vim.o.eventignore
      vim.opt.eventignore:append("BufUnload")
      local ok, res = pcall(orig, ...)
      vim.o.eventignore = saved
      if not ok then error(res) end
      return res
    end
  end,
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add buffer to Claude" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
    { "<leader>aa", resolve_diff("ClaudeCodeDiffAccept"), desc = "Accept diff" },
    { "<leader>ad", resolve_diff("ClaudeCodeDiffDeny"), desc = "Deny diff" },
    -- one key to hop between editor and Claude pane, both directions
    { "<C-q>", "<cmd>ClaudeCodeFocus<cr>", mode = "n", desc = "Focus Claude" },
    { "<C-q>", "<C-\\><C-n><C-w>p", mode = "t", desc = "Back to editor" },
    -- accept/deny without leaving the Claude pane first
    { "<C-a>", resolve_diff("ClaudeCodeDiffAccept"), mode = "t", desc = "Accept diff" },
    { "<C-x>", resolve_diff("ClaudeCodeDiffDeny"), mode = "t", desc = "Deny diff" },
  },
}
