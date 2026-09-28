return {
  "frabjous/knap",
  ft = { "markdown", "html" },
  config = function()
    vim.g.knap_settings = {
      markdownoutputext = "html",
      markdowntohtml = "pandoc %docroot% -o %outputfile%",
      markdowntohtmlviewerlaunch = "open %outputfile%",
      markdowntohtmlviewerrefresh = "osascript -e 'tell application \"Safari\" to do JavaScript \"location.reload()\" in document 1'",
    }
  end,
}
