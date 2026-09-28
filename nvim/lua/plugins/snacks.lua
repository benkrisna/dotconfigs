-- Single snacks.nvim spec (also a dependency of claudecode.nvim and nerdy.nvim).
-- image: renders LaTeX math (and markdown images) via the kitty graphics
-- protocol. Molten's plot output uses image.nvim instead (see image.lua);
-- snacks never attaches to Python buffers.
return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    image = {
      enabled = true,
      doc = {
        enabled = true,
        inline = false, -- don't reflow the buffer while typing
        float = true,   -- rendered equation in a float when the cursor is in math
        max_width = 80,
        max_height = 20,
      },
      math = {
        enabled = true,
        latex = {
          font_size = "Large",
          -- benmacros: shared \newcommands, ~/Library/texmf/tex/latex/local/benmacros.sty
          packages = { "amsmath", "amssymb", "amsfonts", "amscd", "mathtools", "bm", "benmacros" },
        },
      },
    },
  },
}
