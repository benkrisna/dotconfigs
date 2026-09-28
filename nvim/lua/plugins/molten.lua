return {
  "benlubas/molten-nvim",
  build = ":UpdateRemotePlugins",
  init = function()
    vim.g.molten_output_win_max_height = 20
    vim.g.molten_auto_open_output = false
    vim.g.molten_virt_text_output = true
    vim.g.molten_wrap_output = true
    vim.g.molten_image_provider = "image.nvim"
  end,
  config = function()
    local cells = require("user.cells")

    local group = vim.api.nvim_create_augroup("MoltenCells", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "InsertLeave" }, {
      group = group,
      pattern = { "*.py" },
      callback = cells.highlight,
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      pattern = "python",
      callback = function(args)
        local opts = { buffer = args.buf, silent = true }
        vim.keymap.set("n", "<LocalLeader>mi", ":MoltenInit<CR>", opts)
        vim.keymap.set("n", "<LocalLeader>rr", function() cells.run_cell(false) end, opts)
        vim.keymap.set("n", "<LocalLeader>rc", function() cells.run_cell(true) end, opts)
        vim.keymap.set("n", "<LocalLeader>rl", ":MoltenEvaluateLine<CR>", opts)
        vim.keymap.set("x", "<LocalLeader>r", ":<C-u>MoltenEvaluateVisual<CR>", opts)
        vim.keymap.set("n", "<LocalLeader>ro", ":MoltenShowOutput<CR>", opts)
        vim.keymap.set("n", "<LocalLeader>rh", ":MoltenHideOutput<CR>", opts)
        vim.keymap.set("n", "<LocalLeader>rR", ":MoltenRestart!<CR>", opts)
        -- Force-clear + redraw image.nvim overlays: kitty-protocol images
        -- placed via tmux passthrough can get "stuck" on screen when you
        -- scroll the tmux pane directly (tmux doesn't track image
        -- placements against its own scrollback/copy-mode). This is the
        -- manual unstick.
        vim.keymap.set("n", "<LocalLeader>ic", function()
          require("image").clear()
          vim.cmd("redraw!")
        end, opts)
        vim.keymap.set("n", "]c", function() cells.jump(1) end, opts)
        vim.keymap.set("n", "[c", function() cells.jump(-1) end, opts)
      end,
    })
  end,
}
