vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("nnoremap <c-n> :tabprevious<CR>")
vim.cmd("nnoremap <c-m> :tabnext<CR>")
vim.cmd("nnoremap <silent> H ^")
vim.cmd("nnoremap <silent> L $")
vim.cmd("syntax enable")
vim.cmd("set tabstop=4")
vim.cmd("set expandtab")
vim.cmd("set number")
vim.cmd("filetype indent on")
vim.cmd("set autoindent")
vim.cmd("set nocompatible")
vim.cmd("filetype off")
vim.cmd("set ignorecase")
vim.cmd("set smartcase")
vim.cmd("set rnu")
vim.cmd("set clipboard+=unnamedplus")
vim.api.nvim_set_option("clipboard","unnamed")

vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {})
--local opts = {}
--
--require("lazy").setup(opts, plugins)

vim.keymap.set('n', '<leader>v', ':vsplit<CR>', {})
vim.keymap.set('n', '<leader>q', ':wq<CR>', {})
vim.keymap.set('n', '<leader>Q', ':wqa<CR>', {})
vim.keymap.set('n', '<leader>i', ':b#<CR>', {})
vim.keymap.set('n', '<leader>m', ':colorscheme catppuccin-mocha<CR>', {})
vim.keymap.set('n', '<leader>l', ':colorscheme tokyonight-moon<CR>', {})
vim.keymap.set('n', '<leader>s', ':%s/<C-r><C-w>//g<Left><Left>', {})
vim.keymap.set('n', '<leader>8', ':vsplit<CR>gg=G:q<CR>', {})
vim.keymap.set('n', '<leader>t', ':nohlsearch<Bar>:echo<CR>', {})
vim.keymap.set('n', '<leader>h', 'o\\underline{\\textit{}} \\\\ <Left><Left><Left><Left><Left><Left>', {})
vim.keymap.set('n', '<leader>r', ':ClangdSwitchSourceHeader', {})
vim.keymap.set('n', '<leader>i', ':b#<CR>', {})
vim.keymap.set('n', '<leader>u', '0v$U<CR>', {})
vim.keymap.set('n', '<leader>w', '<C-w>h', {})
vim.keymap.set('n', '<leader>e', ':source Session.vim<CR>', {})

-- MAGMA
require('lazy').setup({
    {
        'dccsillag/magma-nvim',
        config = function()
            require('magma').setup()
        end,
    }
})

vim.cmd("nnoremap <silent><expr> <LocalLeader>r  :MagmaEvaluateOperator<CR>")
vim.cmd("nnoremap <silent>       <LocalLeader>rr :MagmaEvaluateLine<CR>")
vim.cmd("xnoremap <silent>       <LocalLeader>r  :<C-u>MagmaEvaluateVisual<CR>")
vim.cmd("nnoremap <silent>       <LocalLeader>rc :MagmaReevaluateCell<CR>")
vim.cmd("nnoremap <silent>       <LocalLeader>rd :MagmaDelete<CR>")
vim.cmd("nnoremap <silent>       <LocalLeader>ro :MagmaShowOutput<CR>")

vim.cmd("let g:magma_automatically_open_output = v:false")
vim.cmd("let g:magma_image_provider = 'ueberzug'")

vim.opt.cursorline = true
