-- Servers are configured by nvim-lspconfig's lsp/ files and enabled with
-- Neovim's built-in vim.lsp.enable() (mason-lspconfig does this automatically
-- for every installed server). Per-server overrides: vim.lsp.config("name", {...}).
return {
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = {
        "lua_ls",
        "ts_ls",
        "bashls",
        "clangd",
        "cmake",
        "ltex",
        "matlab_ls",
        "jedi_language_server",
        "lemminx",
      },
      -- ltex-ls needs a Java runtime (not installed); start it by hand with
      -- :lsp enable ltex once Java is available.
      automatic_enable = { exclude = { "ltex" } },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      vim.lsp.config("*", {
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
      })
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
      vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, {})
    end,
  },
}
