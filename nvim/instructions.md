# Setup: Neovim + Claude Code research workflow (code, figures, LaTeX)

You are Claude Code, running in my terminal on an Apple Silicon Mac. My Neovim config uses lazy.nvim, and my terminal is currently Alacritty. Set up the workflow described below. Work through the phases in order and stop at each **CHECKPOINT** to report back and get my confirmation before continuing.

## Ground rules

- **Inspect my existing config before writing anything.** Look at `~/.config/nvim` (init.lua, lua/ layout, how plugin specs are organized) and match its conventions. Put new plugin specs where my existing ones live, one file per plugin if that's my pattern.
- **Back up first.** If `~/.config/nvim` is a git repo, commit current state on a new branch `claude-research-setup`. If not, copy it to `~/.config/nvim.bak-<date>`.
- **Verify plugin APIs against current READMEs/docs.** The Lua specs and option names below are starting points written from memory. Fetch each plugin's README or docs from GitHub and follow its current recommended setup where it differs. Tell me about any differences you find.
- **Ask before any `brew install`, new app, new terminal, or global Python/TeX install.** Tell me exactly what you'll install and why.
- **Check for keymap conflicts** with my existing mappings before adding new ones. If one conflicts, propose an alternative rather than overriding silently.
- Do not modify my shell rc files, Alacritty config, or TeX distribution unless I approve it.

---

## Phase 0 — Decide image display (ask me first)

Ask me which of these I want:

- **Option A (images inside Neovim):** requires **Ghostty or Kitty**. Do not recommend WezTerm: snacks.nvim documents only limited kitty-graphics support there, without inline rendering. Alacritty cannot display images at all. Option A enables inline plots from Jupyter cells *and* inline rendering of LaTeX equations in `.tex` files (Phase 6).
- **Option B (keep Alacritty):** no images in Neovim. Molten shows text output; matplotlib figures open as native macOS windows via the `macosx` backend; equations are only visible in the compiled PDF.

Everything else is identical for both options. Record my choice and apply it in Phases 3 and 6.

**CHECKPOINT 0:** report what you found in my config (plugin manager layout, leader/localleader, existing Python/LaTeX-related plugins, whether snacks.nvim / nvim-treesitter / VimTeX are already installed, whether `vim.g.python3_host_prog` is set) and confirm Option A or B.

---

## Phase 1 — claudecode.nvim (Claude Code ↔ Neovim integration)

Install `coder/claudecode.nvim`. It implements the same IDE protocol as the official VS Code/JetBrains extensions: diffs open in Neovim, and my current selection/buffer is shared with Claude Code.

Starting-point spec (verify against README):

```lua
return {
  "coder/claudecode.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = true,
  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<cr>",            desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>",       desc = "Focus Claude" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>",       desc = "Add buffer to Claude" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send selection to Claude" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>",  desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>",    desc = "Deny diff" },
  },
}
```

If I already have snacks.nvim, reuse that spec (snacks is configured again in Phase 6; keep a single snacks spec with merged `opts`, not two).

---

## Phase 2 — Python environment for interactive cells

1. Find what Python environment manager I use (conda/mamba, uv, pyenv, plain venv) by checking my shell and existing envs. Don't introduce a new manager.
2. Create (or reuse, with my OK) a dedicated env for Neovim's Python host, e.g. `nvim-py`, with:
   `pynvim jupyter_client ipykernel nbformat jupytext pillow`
   For Option A, also install whatever molten needs for image output per its README.
3. Set `vim.g.python3_host_prog` to that env's python in my config.
4. Make sure my **research env** (numpy/matplotlib/SciencePlots/h5py) has `ipykernel` and is registered as a Jupyter kernel:
   `python -m ipykernel install --user --name research --display-name "research"`
   Ask me which env is my research env if it's not obvious.

---

## Phase 3 — molten-nvim + jupytext.nvim

### molten-nvim (`benlubas/molten-nvim`)

Runs code against a live Jupyter kernel from Neovim. Needs `build = ":UpdateRemotePlugins"`.

Settings to apply:

- `vim.g.molten_output_win_max_height = 20`
- `vim.g.molten_auto_open_output = false`
- `vim.g.molten_virt_text_output = true`
- `vim.g.molten_wrap_output = true`
- **Option B:** `vim.g.molten_image_provider = "none"`
- **Option A:** check molten's README for which image providers it currently supports. If it supports **snacks.nvim**, use that, so snacks is the only image plugin (it's already needed for LaTeX math in Phase 6). If it only supports **image.nvim** (`3rd/image.nvim`), install that with backend `"kitty"`, prefer the `magick_cli` processor if still offered, and limit image size (e.g. `max_width = 100`, `max_height = 12`, `window_overlap_clear_enabled = true`). In that case make sure snacks' document image rendering is not also active in Python buffers, so the two plugins don't draw over each other. Either way, Option A needs ImageMagick (`brew install imagemagick`; ask first).

**Option B only:** in the research kernel, matplotlib should use the `macosx` backend so `plt.show()` opens native windows. Handle this in the figure template (Phase 5), not in a global matplotlibrc.

### Cell execution for `# %%` scripts

My figure scripts use percent-format cells (`# %%` markers). Add a small helper module (e.g. `lua/<my-namespace>/cells.lua`) that finds the current cell's bounds and sends it to molten. Starting point:

```lua
local M = {}

-- Lua pattern: "%%%%" matches a literal "%%"
local MARKER = "^# %%%%"

function M.bounds()
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local s, e = 1, #lines
  for i = cur, 1, -1 do
    if lines[i]:match(MARKER) then s = i + 1; break end
  end
  for i = cur + 1, #lines do
    if lines[i]:match(MARKER) then e = i - 1; break end
  end
  return s, e
end

function M.run_cell(advance)
  local s, e = M.bounds()
  if e < s then return end
  vim.fn.MoltenEvaluateRange(s, e)
  if advance then
    local target = math.min(e + 2, vim.api.nvim_buf_line_count(0))
    vim.api.nvim_win_set_cursor(0, { target, 0 })
  end
end

function M.jump(dir)
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local i = cur + dir
  while i >= 1 and i <= #lines do
    if lines[i]:match(MARKER) then
      vim.api.nvim_win_set_cursor(0, { i, 0 }); return
    end
    i = i + dir
  end
end

return M
```

Verify that `MoltenEvaluateRange` is still the correct function name in molten's README.

Keymaps (buffer-local for Python files, under `<localleader>`; check conflicts):

| Key | Action |
|---|---|
| `<localleader>mi` | `:MoltenInit` (pick kernel) |
| `<localleader>rr` | run current cell, stay |
| `<localleader>rc` | run current cell, advance to next |
| `<localleader>rl` | `:MoltenEvaluateLine` |
| `<localleader>r` (visual) | `:<C-u>MoltenEvaluateVisual<cr>` |
| `<localleader>ro` | `:MoltenShowOutput` / enter output window |
| `<localleader>rh` | `:MoltenHideOutput` |
| `<localleader>rR` | `:MoltenRestart!` |
| `]c` / `[c` | next / previous cell |

Also add a highlight so `# %%` lines are visually distinct, respecting my colorscheme.

### jupytext.nvim (`GCBallesteros/jupytext.nvim`)

When I open an `.ipynb`, show and edit it as a percent-format `.py`, and save back as a notebook. Configure `style = "percent"`, `output_extension = "auto"`. It needs the `jupytext` CLI on PATH; point it at the `nvim-py` env's binary if it isn't globally available.

**CHECKPOINT 3:** tell me to restart Neovim, then run `:Lazy sync`, `:UpdateRemotePlugins`, and `:checkhealth molten` (plus `:checkhealth snacks` or `:checkhealth image` for Option A). Wait for me to report the results.

---

## Phase 4 — Smoke test (Python)

Create `~/tmp/molten_test.py`:

```python
# %%
import numpy as np
import matplotlib.pyplot as plt
x = np.linspace(0, 2*np.pi, 200)
x.shape

# %%
fig, ax = plt.subplots(figsize=(3.5, 2.5))
ax.plot(x, np.sin(x))
plt.show()
```

Walk me through: open the file, `<localleader>mi` → pick `research`, `<localleader>rc` twice. Expected: `(200,)` as virtual text, then a sine plot inline (Option A) or in a macOS window (Option B). Also test `]c`/`[c` and opening a real `.ipynb` via jupytext. Fix anything that fails before moving on.

---

## Phase 5 — Figure project template

Create a reusable template at `~/templates/paper-figures/` (ask me if I'd rather put it elsewhere). Structure:

```
paper-figures/
├── CLAUDE.md            # rules for Claude Code when working on figures (below)
├── Makefile             # `make all`, `make fig03`, `make preview`
├── style/
│   ├── paper.mplstyle   # fonts, sizes, line widths; builds on SciencePlots
│   └── figsize.py       # journal column widths in ONE place
├── data/                # cached, plot-ready arrays (.npz / .h5); gitignored if large
├── extract/             # slow scripts: raw simulation output -> data/
├── figs/                # fast scripts: data/ -> out/  (one per figure, # %% cells)
│   └── fig01_example.py
└── out/                 # generated PDFs (final) and PNGs (preview)
```

Requirements:

- **`figsize.py`:** define single- and double-column widths for JFM and JCP (Elsevier) as named constants plus a helper `figsize(width="single", aspect=0.75)`. Leave the numeric widths as clearly marked `TODO: verify from author guidelines` values; do not guess them silently.
- **`paper.mplstyle`:** build on `["science"]` from SciencePlots with LaTeX text rendering (confirm `latex` is on PATH). Consistent font sizes (e.g. 8–9 pt), thin axes lines.
- **Each `figs/figXX_*.py`** is percent-format, loads only from `data/`, uses the shared style and figsize, and when run as a script writes `out/figXX.pdf` (final, vector) and `out/figXX_preview.png` (150 dpi). The PNG is what Claude inspects.
- **Makefile:** `make figXX` runs one script; `make all` runs all; `make preview` opens the PDF in Skim.
- **Backend:** scripts run headless (`Agg`) under `make`; under an interactive kernel with Option B, use `macosx`.

### `CLAUDE.md` for the figure template

Write this into `paper-figures/CLAUDE.md`, expanded into clear instructions:

1. Never edit `data/` by hand. If a figure needs new data, write or modify a script in `extract/` and tell me it needs to run (it may need HPC output).
2. After any change to a figure script: run `make figXX`, then **open `out/figXX_preview.png` and inspect it yourself** before reporting back. Check for overlapping or clipped labels, legend covering data, colorbar/label clipping, unreadable tick density, inconsistent font sizes vs. other figures, and missing units in axis labels.
3. If the inspection finds problems, fix and re-render (up to 3 iterations) before showing me. Report what you changed and why.
4. Keep figure dimensions from `figsize.py`; never hardcode sizes in individual scripts.
5. Preserve `# %%` cell structure so I can run cells interactively in Neovim.
6. Use colorblind-safe palettes; add line styles/markers when there are more than 3 series.

**CHECKPOINT 5:** show me the template tree and the example figure preview PNG.

---

## Phase 6 — LaTeX: VimTeX + latexmk + Skim SyncTeX (+ inline math for Option A)

Goal: continuous compilation on save, Skim showing the true page layout with forward/inverse search, and (Option A) typeset equations visible inside Neovim while editing.

### 6.1 Check the TeX side

- Confirm `latexmk`, `pdflatex` (and `lualatex` if present), and `synctex` are on PATH, and report my TeX distribution and version. Don't install or update TeX without asking.
- Check that the journal classes I use are available: `kpsewhich jfm.cls elsarticle.cls`. If one is missing, tell me; don't install it.
- Check whether Skim is installed (`/Applications/Skim.app`). If not, ask before `brew install --cask skim`.

### 6.2 VimTeX (`lervag/vimtex`)

VimTeX's docs say it should **not** be lazy-loaded; use `lazy = false` and set its globals in `init` (before it loads). Starting point:

```lua
return {
  "lervag/vimtex",
  lazy = false,
  init = function()
    vim.g.vimtex_view_method = "skim"
    vim.g.vimtex_view_skim_sync = 1       -- forward search after each compile
    vim.g.vimtex_view_skim_activate = 0   -- don't steal focus from the terminal
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_compiler_latexmk = {
      continuous = 1,
      options = { "-synctex=1", "-interaction=nonstopmode", "-file-line-error" },
    }
    vim.g.vimtex_quickfix_open_on_warning = 0
    vim.g.vimtex_quickfix_ignore_filters = { "Underfull", "Overfull" }
  end,
}
```

Keep VimTeX's default `<localleader>l*` mappings (`ll` toggle continuous compile, `lv` forward search, `le` errors, `lc` clean, `lt` TOC). Report any conflicts with my existing maps.

If my projects use a `.latexmkrc` (e.g. an `out_dir`/`aux_dir`), make sure VimTeX respects it rather than overriding it.

### 6.3 Inverse search (Skim → Neovim)

Tell me to set this manually in Skim (don't script Skim prefs): **Preferences → Sync → PDF-TeX Sync support → Preset: Custom**, with Command `nvim` (use the full path from `which nvim`) and Arguments:

```
--headless -c "VimtexInverseSearch %line '%file'"
```

Verify this against VimTeX's current docs (`:h vimtex-synctex-inverse-search`). Also have me enable **Sync → Check for file changes**. Cmd-Shift-click in Skim should then jump Neovim to the source line.

### 6.4 Treesitter and VimTeX

VimTeX recommends its own syntax highlighting for LaTeX rather than treesitter highlighting. But snacks' math rendering (Option A) uses the treesitter `latex` parser to find math. So:

- Install the `latex` treesitter parser (it may require the `tree-sitter` CLI to build; ask before installing that).
- Keep treesitter **highlighting disabled** for `latex` (`highlight.disable = { "latex" }`) so VimTeX's syntax stays in charge.

Confirm with the current VimTeX and snacks docs that this combination is still the recommended one.

### 6.5 Inline equation rendering (Option A only)

Enable snacks.nvim's `image` module in the single snacks spec. Starting point (verify option names in snacks' `docs/image.md`):

```lua
opts = {
  image = {
    enabled = true,
    doc = {
      enabled = true,
      inline = false,   -- don't reflow the buffer while I type
      float = true,     -- show the rendered equation in a float when the cursor is in math
      max_width = 80,
      max_height = 20,
    },
    math = {
      enabled = true,
      latex = {
        font_size = "Large",
        packages = { "amsmath", "amssymb", "amsfonts", "amscd", "mathtools", "bm" },
      },
    },
  },
}
```

**Custom macros matter.** snacks renders each equation as a standalone snippet, so my `\newcommand`s (vectors, operators, units) will fail to render unless they're included. Find where my papers define macros (a `macros.tex`/preamble file). Then use snacks' configurable math template (or `packages` plus a preamble include) to pull in a shared macros file; propose a location such as `~/texmf/tex/latex/local/benmacros.sty` so both papers and snacks can use it. Ask me before moving or duplicating macro definitions.

If I prefer seeing equations rendered in place, show me how to flip `inline = true` and let me decide.

### 6.6 CLAUDE.md for paper repos

Create `~/templates/paper-latex/CLAUDE.md` for me to copy into paper repos. Rules for Claude Code when editing a paper:

1. Build with `latexmk` (same flags as VimTeX). After edits, check the log for errors, undefined references/citations, and multiply-defined labels; report them. Ignore under/overfull box warnings unless I ask.
2. Keep the file's existing line-break convention (e.g. one sentence per line). Never reflow unrelated paragraphs; diffs must show only real changes.
3. Never rename `\label` keys or edit `.bib` entries without asking.
4. Figures come from the `paper-figures` pipeline's `out/*.pdf`; don't edit figure PDFs or embed figure-generation code in the paper.
5. Use the shared macros file; add new macros there rather than inline, and tell me when you add one.
6. For substantive text changes (claims, results, wording of conclusions), propose them as a diff for review rather than applying silently.

### 6.7 Smoke test (LaTeX)

Create `~/tmp/vimtex_test/main.tex` using `article` (and, if available, a second copy with `jfm`), containing an inline equation, a display equation using `align`, one of my custom macros, and a `\label`/`\eqref` pair. Walk me through:

1. `<localleader>ll` → continuous compile starts; Skim opens without stealing focus.
2. Edit and save → Skim updates.
3. `<localleader>lv` → forward search highlights the current line in Skim.
4. Cmd-Shift-click in Skim → Neovim jumps to the source line.
5. **Option A:** cursor inside an equation → rendered equation appears (including the custom macro).

**CHECKPOINT 6:** report results of each step and fix failures before finishing.

---

## Phase 7 — Manual steps for me (list at the end; don't do these)

- Skim: Sync preset for inverse search and "Check for file changes" (from 6.3), if not done during the smoke test.
- Option A: install and configure Ghostty or Kitty (font, theme, keybindings), then launch Neovim from it.
- Copy `paper-latex/CLAUDE.md` and `paper-figures/` into real paper repos as needed; set `.gitignore` for `data/`, `build/`, and LaTeX aux files.
- Fill in the journal column widths in `figsize.py`.

Finish with a short summary: files created/changed, new keymaps (Python and LaTeX), how to start a new figure project and a new paper from the templates, and how to roll back (branch name or backup path).
