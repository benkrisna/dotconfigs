return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    local parsers = {
      "lua", "vim", "vimdoc", "javascript", "c", "cpp", "xml", "python",
      "bash", "cmake", "markdown", "markdown_inline", "latex",
    }
    require("nvim-treesitter").install(parsers)

    -- VimTeX provides LaTeX syntax highlighting; the latex parser is only
    -- installed for plugins that query it (e.g. snacks math rendering).
    local no_highlight = { latex = true }

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
      callback = function(args)
        local lang = vim.treesitter.language.get_lang(args.match)
        if not lang or no_highlight[lang] then return end
        if pcall(vim.treesitter.start, args.buf, lang) then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
