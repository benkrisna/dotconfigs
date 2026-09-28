return {
  "3rd/image.nvim",
  -- Pinned just before commit c30811d ("account for extmark conceal when
  -- resolving image x position", 2026-09): that change and its follow-up
  -- a2f313a crash with "attempt to compare number with nil" in
  -- resolve_concealed_screen_x (win_info.leftcol comes back nil) when
  -- rendering images from molten. Unpin once upstream fixes it.
  commit = "9adf7c7",
  build = false,
  opts = {
    backend = "kitty",
    processor = "magick_cli",
    max_width = 100,
    max_height = 12,
    max_height_window_percentage = math.huge,
    window_overlap_clear_enabled = true,
    -- Clear images when switching away from this tmux window/pane, instead
    -- of leaving stale kitty-protocol overlays behind.
    tmux_show_only_in_active_window = true,
  },
}
