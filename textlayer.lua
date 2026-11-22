-- mod-version:3
--
-- textlayer: click (or press Enter on) a .pdf / .djvu file in the treeview
-- to read its text layer in a new, unsaved tab instead of opening the binary.
--
-- Text is extracted in the background with `pdftotext` (poppler) and
-- `djvutxt` (DjVuLibre), so both must be installed. Nothing is written next
-- to your files: the output goes to a temporary file in USERDIR that is
-- removed right after it is read. Scans without OCR have no text layer and
-- produce a message instead of an empty tab.
--
-- Configuration (all optional), e.g. in your user init.lua:
--   config.plugins.textlayer.pdftotext = "C:/path/to/pdftotext.exe"
--   config.plugins.textlayer.djvutxt   = "C:/path/to/djvutxt.exe"

local core = require "core"
local common = require "core.common"
local config = require "core.config"
local command = require "core.command"
local treeview = require "plugins.treeview"

config.plugins.textlayer = common.merge({
  -- executables; the bare names are looked up in PATH
  pdftotext = "pdftotext",
  djvutxt = "djvutxt",
  config_spec = {
    name = "Text Layer",
    {
      label = "pdftotext",
      description = "Path or name of the pdftotext executable (poppler).",
      path = "pdftotext",
      type = "string",
      default = "pdftotext",
    },
    {
      label = "djvutxt",
      description = "Path or name of the djvutxt executable (DjVuLibre).",
      path = "djvutxt",
      type = "string",
      default = "djvutxt",
    },
  },
}, config.plugins.textlayer)

local function tool_for(ext)
  local c = config.plugins.textlayer
  if ext == "pdf" then
    return { c.pdftotext, "-enc", "UTF-8" }
  elseif ext == "djvu" or ext == "djv" then
    return { c.djvutxt }
  end
end

local counter = 0

local function open_text_layer(path, tool)
  local name = path:match("([^/" .. string.char(92) .. "]+)$") or path
  counter = counter + 1
  local out = string.format("%s%stextlayer-%d-%d.tmp", USERDIR, PATHSEP, os.time(), counter)
  local cmd = {}
  for _, a in ipairs(tool) do cmd[#cmd + 1] = a end
  cmd[#cmd + 1] = path
  cmd[#cmd + 1] = out

  local started, proc = pcall(process.start, cmd)
  if not started or not proc then
    core.error("textlayer: cannot start %s: %s", cmd[1], tostring(proc))
    return
  end
  core.log("Extracting text layer: %s ...", name)

  core.add_thread(function()
    while proc:running() do coroutine.yield(0.1) end
    local f = io.open(out, "rb")
    local text = f and f:read("a") or ""
    if f then f:close() end
    os.remove(out)
    text = text:gsub("\r", ""):gsub("\f", "\n\n")
    if not text:find("%S") then
      core.error("No text layer in %s (scanned without OCR?)", name)
      return
    end
    local doc = core.open_doc()
    doc:insert(1, 1, text)
    doc:clean()
    -- keep the session workspace from saving the whole book as an "unsaved" document
    doc.new_file = false
    doc.get_name = function() return name .. " (text)" end
    core.root_view:open_doc(doc)
    core.log("Text layer of %s: %d lines", name, #doc.lines)
  end)
end

local entry = command.map["treeview:open"]
local original = entry.perform
entry.perform = function(...)
  local item = treeview.selected_item
  if item and item.type ~= "dir" then
    local ext = item.abs_filename:lower():match("%.(%w+)$")
    local tool = ext and tool_for(ext)
    if tool then
      open_text_layer(item.abs_filename, tool)
      return
    end
  end
  return original(...)
end
