Set WshShell = WScript.CreateObject("WScript.Shell")
Set shortcut = WshShell.CreateShortcut("Mouse Shortcuts - Shortcut.lnk")

shortcut.TargetPath = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
shortcut.Arguments = """c:/Users/Test/Desktop/vmcreation/mouse_shortcuts.ahk"""
shortcut.WorkingDirectory = "c:/Users/Test/Desktop/vmcreation"
shortcut.Description = "Run mouse shortcuts script"

shortcut.Save

WScript.Echo "Shortcut created successfully!"