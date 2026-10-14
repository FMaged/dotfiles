-- <leader>cp previews the current file the way it is meant to be seen:
--   Markdown                 -> full-screen reading view inside nvim; q goes back to the file
--     cursor in ```mermaid   -> that diagram as a picture, in place of the zellij pane
--   OpenAPI / AsyncAPI spec  -> Scalar API reference in the browser, reloads on save
--   draw.io diagram          -> the diagram as a picture, in place of the zellij pane
--   anything else            -> the system's default application
-- The browser preview for markdown is <leader>cP (plugins/markdown.lua).
local M = {}

local preload = vim.fn.stdpath("config") .. "/scripts/localhost-only.mjs"

-- path -> job id of the running Scalar server
local servers = {}

local function is_api_spec(buf)
  local ft = vim.bo[buf].filetype
  if ft ~= "yaml" and ft ~= "json" and ft ~= "jsonc" then
    return false
  end
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, 50, false)) do
    for _, key in ipairs({ "openapi", "swagger", "asyncapi" }) do
      if line:match("^%s*[\"']?" .. key .. "[\"']?%s*:") then
        return true
      end
    end
  end
  return false
end

local function is_drawio(path)
  for _, suffix in ipairs({ "%.drawio$", "%.dio$", "%.drawio%.svg$", "%.drawio%.png$" }) do
    if path:match(suffix) then
      return true
    end
  end
  return false
end

-- A read-only copy of the buffer (so unsaved changes show too), rendered by
-- render-markdown in a centred full-screen window.
local function view_markdown(buf)
  local view = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(view, 0, -1, false, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  vim.bo[view].bufhidden = "wipe"
  local bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  Snacks.win({
    buf = view,
    enter = true,
    width = math.min(100, vim.o.columns),
    height = 0,
    border = "none",
    backdrop = { transparent = false, blend = 0, bg = bg and ("#%06x"):format(bg) or nil },
    wo = { wrap = true, linebreak = true, cursorline = false, spell = false },
    keys = { q = "close", ["<Esc>"] = "close" },
  })
  vim.bo[view].filetype = "markdown"
  vim.bo[view].modifiable = false
end

local function free_port()
  local tcp = vim.uv.new_tcp()
  if not tcp then
    return nil
  end
  local port
  if tcp:bind("127.0.0.1", 0) then
    local addr = tcp:getsockname()
    port = addr and addr.port
  end
  tcp:close()
  return port
end

local function serve_spec(path)
  local port = free_port()
  if not port then
    vim.notify("No free port for the API preview", vim.log.levels.ERROR)
    return
  end
  local url = ("http://localhost:%d"):format(port)
  local opened, output = false, {}
  local function on_output(_, data)
    for _, line in ipairs(data) do
      if line ~= "" then
        output[#output + 1] = line
      end
      if not opened and line:find("listening on", 1, true) then
        opened = true
        vim.schedule(function()
          vim.ui.open(url)
        end)
      end
    end
  end
  local node_options = vim.env.NODE_OPTIONS and (vim.env.NODE_OPTIONS .. " ") or ""
  local job = vim.fn.jobstart({ "scalar", "document", "serve", path, "--watch", "--port", tostring(port) }, {
    cwd = vim.fs.dirname(path),
    env = { NODE_OPTIONS = node_options .. "--import=" .. preload },
    on_stdout = on_output,
    on_stderr = on_output,
    on_exit = function(id, code)
      if servers[path] == id then
        servers[path] = nil
      end
      -- 143 = stopped by us (SIGTERM)
      if code ~= 0 and code ~= 143 then
        vim.schedule(function()
          local msg = vim.trim(table.concat(output, "\n"):gsub("\27%[[%d;?]*%a", ""))
          vim.notify("API preview stopped (exit " .. code .. ")\n" .. msg, vim.log.levels.ERROR)
        end)
      end
    end,
  })
  if job <= 0 then
    vim.notify("Could not start `scalar`. Is @scalar/cli installed?", vim.log.levels.ERROR)
    return
  end
  servers[path] = job
  vim.notify("API preview: " .. url .. " (reloads on save, <leader>cp again to stop)")
end

local function open_app(path)
  if is_drawio(path) then
    if vim.fn.jobstart({ "drawio", path }, { detach = true }) <= 0 then
      vim.notify("Could not start `drawio`. Is draw.io desktop installed?", vim.log.levels.ERROR)
    end
    return
  end
  local _, err = vim.ui.open(path)
  if err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end

-- Shows the image in place of this zellij pane until a key is pressed; nvim's own
-- terminal cannot draw images, zellij can (if the terminal has sixel enabled).
local show_image = [[
read -r rows cols < <(stty size)
chafa --size "${cols}x$((rows - 2))" --align mid,mid "$1"
printf '\n  press any key to go back'
read -rsn1
]]

-- Rendered PNGs, named by a hash of the diagram's source, so showing an unchanged
-- diagram again is instant (draw.io takes several seconds to start).
local cache_dir = vim.fn.stdpath("cache") .. "/diagrams"
local cache_days = 30

local function prune_cache()
  local cutoff = os.time() - cache_days * 24 * 3600
  for name, kind in vim.fs.dir(cache_dir) do
    local file = cache_dir .. "/" .. name
    local stat = kind == "file" and vim.uv.fs_stat(file)
    if stat and stat.mtime.sec < cutoff then
      os.remove(file)
    end
  end
end

-- Renders a draw.io or Mermaid (.mmd) file with draw.io and shows the picture.
-- Returns false when it can't (not in zellij, or chafa missing).
local function show_diagram(src, name, source_text)
  if not vim.env.ZELLIJ or vim.fn.executable("chafa") == 0 then
    vim.notify("Showing diagrams needs zellij and chafa (sudo apt install chafa)", vim.log.levels.WARN)
    return false
  end
  vim.fn.mkdir(cache_dir, "p")
  local png = ("%s/%s.png"):format(cache_dir, vim.fn.sha256(source_text))
  local function show()
    local now = os.time()
    vim.uv.fs_utime(png, now, now) -- keeps it out of the next prune
    vim.fn.jobstart({ "zellij", "run", "--in-place", "--close-on-exit", "--name", name, "--", "bash", "-c", show_image, "_", png })
  end
  if vim.uv.fs_stat(png) then
    show()
    return true
  end
  prune_cache()
  vim.notify("Rendering " .. name .. " …")
  -- written next to the cache entry and renamed when complete, so a failed export is never cached
  local part = png .. ".part.png"
  local cmd = { "drawio", "--export", "--format", "png", "--scale", "2", "--border", "20", "--output", part, src }
  local job = vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 or not vim.uv.fs_stat(part) then
          os.remove(part)
          vim.notify("draw.io could not render " .. name .. " (if the draw.io app is open, close it and retry)", vim.log.levels.ERROR)
          return
        end
        vim.uv.fs_rename(part, png)
        show()
      end)
    end,
  })
  if job <= 0 then
    vim.notify("Could not start `drawio`. Is draw.io desktop installed?", vim.log.levels.ERROR)
  end
  return true
end

-- Lines inside the ```mermaid block the cursor is in, or nil.
local function mermaid_at_cursor(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  -- on a bare ``` line the cursor may be on the block's closing fence
  local from = (lines[row] or ""):match("^%s*```%s*$") and row - 1 or row
  local open
  for i = from, 1, -1 do
    if lines[i]:match("^%s*```") then
      open = lines[i]:match("^%s*```%s*mermaid%s*$") and i
      break
    end
  end
  if not open then
    return nil
  end
  for i = open + 1, #lines do
    if lines[i]:match("^%s*```%s*$") then
      return i >= row and vim.list_slice(lines, open + 1, i - 1) or nil
    end
  end
  return nil
end

-- <leader>cp
function M.toggle()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype == "markdown" then
    local block = mermaid_at_cursor(buf)
    if block then
      local mmd = vim.fn.tempname() .. ".mmd"
      vim.fn.writefile(block, mmd)
      show_diagram(mmd, "mermaid diagram", table.concat(block, "\n"))
    else
      view_markdown(buf)
    end
    return
  end
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" or vim.bo[buf].buftype ~= "" then
    vim.notify("Nothing to preview: this buffer is not a file", vim.log.levels.WARN)
    return
  end
  if is_api_spec(buf) then
    if servers[path] then
      vim.fn.jobstop(servers[path])
      servers[path] = nil
      vim.notify("API preview stopped")
    else
      serve_spec(path)
    end
  elseif is_drawio(path) then
    local ok, lines = pcall(vim.fn.readfile, path, "b")
    if not ok then
      vim.notify("Save the diagram first: " .. path, vim.log.levels.WARN)
    elseif not show_diagram(path, vim.fs.basename(path), table.concat(lines, "\n")) then
      open_app(path)
    end
  else
    open_app(path)
  end
end

-- <leader>cP: the file in its own app (draw.io for diagrams). Markdown buffers map
-- <leader>cP to the browser preview instead.
function M.open_app()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" or vim.bo.buftype ~= "" then
    vim.notify("Nothing to open: this buffer is not a file", vim.log.levels.WARN)
    return
  end
  open_app(path)
end

return M
