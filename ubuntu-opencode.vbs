Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell = CreateObject("WScript.Shell")

' Get the current directory
strCurrentDir = objFSO.GetParentFolderName(WScript.ScriptFullName)

' Change to the current directory
objShell.CurrentDirectory = strCurrentDir

' Run the batch file without showing console window
objShell.Run "cmd.exe /c connect-ubuntu58-1-opencode.bat", 0, False
