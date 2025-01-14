return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "ts_ls",
          "bashls",
          "clangd",
          "cmake",
          "ltex",
          "matlab_ls",
          "jedi_language_server",
          "lemminx"
        }
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({
        capabilities = capabilities
      })
      lspconfig.ts_ls.setup({
        capabilities = capabilities
      })
      lspconfig.bashls.setup({
        capabilities = capabilities
      })
      lspconfig.clangd.setup({
        capabilities = capabilities
      })
      lspconfig.cmake.setup({
        capabilities = capabilities
      })
      lspconfig.ltex.setup({
        capabilities = capabilities
      })
      lspconfig.matlab_ls.setup({
        capabilities = capabilities
      })
      lspconfig.jedi_language_server.setup({
        capabilities = capabilities
      })
      lspconfig.lemminx.setup({
        capabilities = capabilities
      })
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
      vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, {})
    end
  }
}
