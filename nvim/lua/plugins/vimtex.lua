return {
  "lervag/vimtex",
  lazy = false,
  init = function()
    vim.g.vimtex_view_method = "skim"
    vim.g.vimtex_view_skim_sync = 1        -- forward search after compile
    vim.g.vimtex_view_skim_activate = 0    -- keep focus in nvim; sync Skim without stealing focus
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_compiler_latexmk = {
      continuous = 1,                      -- latexmk -pvc: watch & recompile on save
      options = {
        "-shell-escape",
        "-synctex=1",
        "-interaction=nonstopmode",
      },
    }
    vim.g.tex_flavor = "latex"
    vim.g.vimtex_quickfix_mode = 0         -- don't auto-open quickfix

    -- auto-start continuous compilation so preview updates on every save
    -- without needing to remember \ll
    vim.api.nvim_create_autocmd("User", {
      pattern = "VimtexEventInitPost",
      callback = function()
        vim.cmd("VimtexCompile")
      end,
    })
  end,
}
