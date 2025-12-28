Set WshShell = WScript.CreateObject("WScript.Shell")
Set shortcut = WshShell.CreateShortcut("connect-ubuntu58-1-opencode - Shortcut.lnk")

shortcut.TargetPath = WshShell.CurrentDirectory & "\connect-ubuntu58-1-opencode.bat"
shortcut.WorkingDirectory = WshShell.CurrentDirectory
shortcut.Description = "SSH to ubuntu58-1 and run opencode"
shortcut.Hotkey = "CTRL+SHIFT+T"

shortcut.Save

WScript.Echo "Shortcut created successfully!"
WScript.Echo "Keyboard shortcut: Ctrl+Shift+T"
WScript.Echo ""
WScript.Echo "You can now press Ctrl+Shift+T to connect to ubuntu58-1 and run opencode."
