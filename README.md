# lite-xl-textlayer

A [Lite XL](https://lite-xl.com) plugin: click a `.pdf` or `.djvu` file in the
sidebar (treeview) to read its **text layer** in a new tab instead of opening
the binary file.

* PDF text comes from `pdftotext` ([poppler](https://poppler.freedesktop.org/)).
* DjVu text comes from `djvutxt` ([DjVuLibre](https://djvu.sourceforge.net/)).
* Extraction runs in the background; the result opens in an unsaved tab named
  `<file> (text)` (searchable, copyable, closes without a save prompt).
* Scans without OCR have no text layer; you get a message instead of an empty tab.
* Pages are separated by a blank line.

## Install

Copy `textlayer.lua` into your Lite XL `plugins` folder (user or data directory)
and make sure `pdftotext` / `djvutxt` are in `PATH`, or set their paths:

```lua
-- user init.lua
local config = require "core.config"
config.plugins.textlayer = {
  pdftotext = "C:/tools/poppler/bin/pdftotext.exe",
  djvutxt   = "C:/tools/DjVuLibre/djvutxt.exe",
}
```

Requires Lite XL 2.1+ (plugin API `mod-version:3`) with the bundled `treeview` plugin.
Tested on Lite XL 2.1.8, Windows.

## License

MIT
