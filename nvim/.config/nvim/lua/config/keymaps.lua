-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- markdown too: LazyVim's browser preview is moved to <leader>cP (plugins/markdown.lua)
vim.keymap.set("n", "<leader>cp", function()
  require("preview").toggle()
end, { desc = "Preview in terminal (markdown, draw.io) or browser (API spec)" })

-- markdown buffers keep their own <leader>cP: the browser preview
vim.keymap.set("n", "<leader>cP", function()
  require("preview").open_app()
end, { desc = "Open in app (draw.io, default app)" })
