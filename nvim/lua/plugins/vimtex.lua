return {
    'lervag/vimtex',
  config = function()
    require('lualine').setup({
      options = {
        theme = 'dracula'
      }
    })
vim.cmd("filetype off")
    vim.cmd("filetype plugin indent on")

    vim.cmd("syntax enable")

    -- vim.cmd("let g:vimtex_view_method = 'zathura'")

    -- vim.cmd("let g:vimtex_view_general_viewer = 'okular'")

    -- vim.cmd("let g:vimtex_compiler_method = 'latexrun'")

end
}
