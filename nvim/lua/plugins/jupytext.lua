return {
  "GCBallesteros/jupytext.nvim",
  lazy = false,
  init = function()
    -- jupytext.nvim shells out to `jupytext` on PATH, but the CLI only
    -- lives in the nvim-py conda env, not globally, so prepend it here
    -- (this only affects Neovim's own process PATH, not the shell rc).
    local nvim_py_bin = "/opt/homebrew/Caskroom/miniconda/base/envs/nvim-py/bin"
    if not string.find(vim.env.PATH, nvim_py_bin, 1, true) then
      vim.env.PATH = nvim_py_bin .. ":" .. vim.env.PATH
    end
  end,
  opts = {
    style = "percent",
    output_extension = "auto",
    force_ft = nil,
  },
}
