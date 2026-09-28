# Setup: Neovim + Claude Code research & figure workflow

You are Claude Code, running in my terminal on an Apple Silicon Mac. My Neovim config uses lazy.nvim, and my terminal is currently Alacritty. Set up the workflow described below. Work through the phases in order and stop at each **CHECKPOINT** to report back and get my confirmation before continuing.

## Ground rules

- **Inspect my existing config before writing anything.** Look at `~/.config/nvim` (init.lua, lua/ layout, how plugin specs are organized) and match its conventions. Put new plugin specs where my existing ones live, one file per plugin if that's my pattern.
- **Back up first.** If `~/.config/nvim` is a git repo, commit current state on a new branch `claude-research-setup`. If not, copy it to `~/.config/nvim.bak-<date>`.
- **Verify plugin APIs against current READMEs.** The Lua specs below are starting points written from memory. Fetch each plugin's README from GitHub and follow its current recommended setup where it differs.
- **Ask before any `brew install`, new terminal app, or global Python install.** Tell me exactly what you'll install and why.
- **Check for keymap conflicts** with my existing mappings before adding new ones. If one conflicts, propose an alternative rather than overriding silently.
- Do not modify my LaTeX setup, shell rc files, or Alacritty config unless I approve it.

---

## Phase 0 — Decide image display (ask me first)

Ask me which of these I want:

- **Option A (inline plots in Neovim):** requires a terminal with the kitty graphics protocol, meaning Ghostty, Kitty, or WezTerm. Alacritty cannot display inline images. Plots render inside Neovim via image.nvim.
- **Option B (keep Alacritty):** no inline images. Molten shows text output in Neovim; matplotlib figures open as native macOS windows via the `macosx` backend.

Everything else in this setup is identical for both options. Record my choice and apply it in Phases 2–3.

**CHECKPOINT 0:** report what you found in my config (plugin manager layout, leader/localleader, existing Python-related plugins, whether `vim.g.python3_host_prog` is set) and confirm Option A or B.

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

If I already have snacks.nvim, reuse it rather than adding a duplicate.

---

## Phase 2 — Python environment for interactive cells

1. Find what Python environment manager I use (conda/mamba, uv, pyenv, plain venv) by checking my shell and existing envs. Don't create a new manager.
2. Create (or reuse, with my OK) a dedicated env for Neovim's Python host, e.g. `nvim-py`, with:
   `pynvim jupyter_client ipykernel nbformat jupytext pillow`
   For Option A, also install whatever image.nvim/molten need for image output per their READMEs.
3. Set `vim.g.python3_host_prog` to that env's python in my config.
4. Separately, make sure my **research env** (the one with numpy/matplotlib/SciencePlots/h5py) has `ipykernel` and is registered as a Jupyter kernel:
   `python -m ipykernel install --user --name research --display-name "research"`
   Ask me which env is my research env if it's not obvious.

---

## Phase 3 — molten-nvim + jupytext.nvim

### molten-nvim (`benlubas/molten-nvim`)

Runs code against a live Jupyter kernel from Neovim. Needs `build = ":UpdateRemotePlugins"`.

Settings to apply:

- `vim.g.molten_output_win_max_height = 20`
- `vim.g.molten_auto_open_output = false` (open output on demand; less clutter)
- `vim.g.molten_virt_text_output = true` (short outputs appear as virtual text under the cell)
- `vim.g.molten_wrap_output = true`
- **Option A:** `vim.g.molten_image_provider = "image.nvim"`
- **Option B:** `vim.g.molten_image_provider = "none"`

**Option A only:** install `3rd/image.nvim` with backend `"kitty"` (this also works for Ghostty). Prefer the `magick_cli` processor if the README still offers it, since it avoids building the magick luarock. This needs ImageMagick (`brew install imagemagick`; ask first). Limit image size so plots don't take over the buffer (e.g. `max_width = 100`, `max_height = 12`, `max_height_window_percentage = math.huge`, `window_overlap_clear_enabled = true`).

**Option B only:** in the research kernel, matplotlib should use the `macosx` backend so `plt.show()` opens native windows. Add a note in the figure template's style setup (Phase 5) rather than changing global matplotlibrc.

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

Also add a highlight so `# %%` lines are visually distinct (e.g. underline or a subtle background via an extmark or matchadd), respecting my colorscheme.

### jupytext.nvim (`GCBallesteros/jupytext.nvim`)

So that when I (or a collaborator) open an `.ipynb`, it's shown and edited as a percent-format `.py`, and saved back as a notebook. Configure `style = "percent"`, `output_extension = "auto"`, `force_ft = nil`. It needs the `jupytext` CLI on PATH; point it at the `nvim-py` env's binary if it isn't globally available.

**CHECKPOINT 3:** tell me to restart Neovim, then run `:Lazy sync`, `:UpdateRemotePlugins`, and `:checkhealth molten` (and `:checkhealth image` for Option A). Wait for me to report the results.

---

## Phase 4 — Smoke test

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

Create a reusable template at `~/templates/paper-figures/` (ask me if I'd rather put it somewhere else). Structure:

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

- **`figsize.py`:** define single-column and double-column widths for JFM and JCP (Elsevier) as named constants plus a helper `figsize(width="single", aspect=0.75)`. Leave the numeric widths as clearly marked `TODO: verify from author guidelines` values; do not guess them silently.
- **`paper.mplstyle`:** build on `["science"]` from SciencePlots with LaTeX text rendering (I have a TeX install; confirm `latex` is on PATH). Consistent font sizes (e.g. 8–9 pt), thin axes lines, no top/right ticks unless specified.
- **Each `figs/figXX_*.py`** is percent-format, loads only from `data/`, uses the shared style and figsize, and when run as a script writes both `out/figXX.pdf` (final, vector) and `out/figXX_preview.png` (150 dpi). The PNG is what Claude inspects.
- **Makefile:** `make figXX` runs one script; `make all` runs all; `make preview` opens the PDF in Skim.
- **Option B note:** at the top of each fig script, the interactive backend is only set when running under a kernel, so `make` runs stay headless (`Agg`).

### `CLAUDE.md` for the template

Write this into `paper-figures/CLAUDE.md`, expanded into clear instructions:

1. Never edit `data/` by hand. If a figure needs new data, write or modify a script in `extract/` and tell me it needs to run (it may need HPC output).
2. After any change to a figure script: run `make figXX`, then **open `out/figXX_preview.png` and inspect it yourself** before reporting back. Check for overlapping or clipped labels, legend covering data, colorbar/label clipping, unreadable tick density, inconsistent font sizes vs. other figures, and missing units in axis labels.
3. If the inspection finds problems, fix and re-render (up to 3 iterations) before showing me. Report what you changed and why.
4. Keep figure dimensions from `figsize.py`; never hardcode figure sizes in individual scripts.
5. Preserve `# %%` cell structure so I can run cells interactively in Neovim.
6. Use colorblind-safe palettes; use line style/markers in addition to color when there are more than 3 series.

**CHECKPOINT 5:** show me the template tree and the example figure preview PNG.

---

## Phase 6 — Manual steps for me (list at the end; don't do these)

- Install Skim if I don't have it (`brew install --cask skim`, only if I approve) and turn on **Preferences → Sync → Check for file changes** so PDFs auto-reload.
- If I chose Option A: install and configure the new terminal, then launch Neovim from it.
- Add `data/` size policy to `.gitignore` in real paper repos as needed.

Finish with a short summary: files created/changed, new keymaps, how to start a new figure project from the template, and how to roll back (branch name or backup path).
