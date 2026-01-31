# AGENTS.md - Project Contract

## AutoHotkey Mouse Shortcut Setup

- AutoHotkey installed at: `C:\Program Files\AutoHotkey\v2` (v2) and `C:\Program Files\AutoHotkey\UX` (v1)
- Mouse shortcuts script: `c:/Users/Test/Desktop/vmcreation/mouse_shortcuts.ahk`
  - Maps middle mouse button to hold Alt+A while pressed.
  - Maps XButton1 and XButton2 to send Enter.
  - AutoHotkey v1 syntax (for compatibility with file association).
- Shortcut to run script: `c:/Users/Test/Desktop/vmcreation/Mouse Shortcuts - Shortcut.lnk`
  - Targets: `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`
  - Arguments: `"c:/Users/Test/Desktop/vmcreation/mouse_shortcuts.ahk"`

.ahk files are associated with v1. Double-clicking the script runs it with v1. The shortcut runs with v2.