vim.cmd("set expandtab")
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")
-- <C-m> is the same key as <CR> in terminals, so tab switching uses <C-n>/<C-p>
vim.cmd("nnoremap <c-n> :tabnext<CR>")
vim.cmd("nnoremap <c-p> :tabprevious<CR>")
vim.cmd("nnoremap <silent> H ^")
vim.cmd("nnoremap <silent> L $")
vim.cmd("syntax enable")
vim.cmd("set number")
vim.cmd("filetype indent on")
vim.cmd("set autoindent")
vim.cmd("set ignorecase")
vim.cmd("set smartcase")
vim.cmd("set rnu")
vim.opt.clipboard = "unnamed"

vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
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

require("lazy").setup("plugins", {
  rocks = { enabled = false }, -- no plugin needs luarocks
})

vim.keymap.set('n', '<leader>v', ':vsplit<CR>', {})
vim.keymap.set('n', '<leader>q', ':wq<CR>', {})
vim.keymap.set('n', '<leader>Q', ':wqa<CR>', {})
vim.keymap.set('n', '<leader>i', ':b#<CR>', {})
vim.keymap.set('n', '<leader>m', ':colorscheme catppuccin-mocha<CR>', {})
vim.keymap.set('n', '<leader>l', ':colorscheme tokyonight-moon<CR>', {})
vim.keymap.set('n', '<leader>s', ':%s/<C-r><C-w>//g<Left><Left>', {})
vim.keymap.set('n', '<leader>8', ':vsplit<CR>gg=G:q<CR>', {})
vim.keymap.set('n', '<leader>t', ':nohlsearch<Bar>:echo<CR>', {})
-- vim.keymap.set('n', '<leader>h', 'o\\underline{\\textit{}} \\\\ <Left><Left><Left><Left><Left><Left>', {})
vim.keymap.set('n', '<leader>h', ':LspClangdSwitchSourceHeader<CR>', {})
vim.keymap.set('n', '<leader>u', '0v$U<CR>', {})
vim.keymap.set('n', '<leader>w', '<C-w>h', {})
vim.keymap.set('n', '<leader>e', ':source Session.vim<CR>', {})

vim.opt.cursorline = true

-- Neovim's Python host, used by molten-nvim etc.
vim.g.python3_host_prog = "/opt/homebrew/Caskroom/miniconda/base/envs/nvim-py/bin/python"

-- Remap Copilot accept function to Ctrl + l
vim.api.nvim_set_keymap("i", "<C-l>", 'copilot#Accept("<CR>")', { silent = true, expr = true, script = true })
vim.g.copilot_no_tab_map = true


