-- In markdown, <leader>cp opens the reading view (lua/preview.lua);
-- LazyVim's browser preview moves to <leader>cP.
return {
  {
    "iamcco/markdown-preview.nvim",
    keys = {
      { "<leader>cp", false, ft = "markdown" },
      { "<leader>cP", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Markdown Preview (browser)" },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      -- LazyVim turns heading icons and checkboxes off; bring them back
      heading = { icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " }, border = true },
      checkbox = { enabled = true },
      pipe_table = { preset = "round" },
      code = { border = "thick" },
      -- the reading view is a nofile buffer: render every line, even the one under the cursor
      overrides = { buftype = { nofile = { anti_conceal = { enabled = false } } } },
    },
  },
}
