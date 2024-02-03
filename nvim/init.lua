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
vim.cmd("set rnu")

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

require("lazy").setup("plugins")
local opts = {}

require("lazy").setup(plugins, opts)
