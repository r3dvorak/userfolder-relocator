# UserFolder Relocator

A PowerShell script to safely **relocate Windows user folders** (Documents, Downloads, Pictures, Music, Videos, Desktop, Favorites, Contacts) from their default location in `C:\Users\<username>` to another drive or base path (e.g. `D:\Gerhard`).  

This script updates the **registry entries** in  
`HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders`  
and moves the files using **robocopy**, ensuring file attributes and timestamps are preserved.  

---

## ✨ Features

- Relocates standard Windows *Known Folders* (Documents, Pictures, etc.)
- Supports **dry-run mode** (preview changes without moving anything)
- Provides an **interactive menu** to choose which folders to move
- Detects if a folder is already redirected and lets you skip or continue
- Asks before creating the base path if it doesn’t exist
- Shows a **progress bar** for folder operations
- Logs all actions to a file (`UserFolderMove.log`)

---

## 🔧 Requirements

- Windows 10 or 11  
- PowerShell 5+  
- `robocopy` (included with Windows)  
- Execution Policy allowing local scripts

If you’ve never run custom PowerShell scripts before, you may need to enable execution once:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```
---

## 🚀 Usage

1. Clone or download this repository.  
2. Open PowerShell.  
3. Run the script (adjust path as needed):  
   ```powershell
   D:\moveuserfolders.ps1
4. Enter the new base path (e.g. D:\Gerhard).
5. Choose dry-run (Y) to preview, or N to actually move.
6. Select which folders to relocate from the menu.

## 📝 Example Run

```powershell
Enter the new base path (e.g. D:\Gerhard): D:\Gerhard
=== Starting User Folder Move Script ===
Run in dry-run mode (no changes made)? (Y/N): Y

Select which folders to move (comma-separated numbers, or press Enter for all):
[1] Documents
[2] Music
[3] Pictures
[4] Downloads
[5] Desktop
[6] Favorites
[7] Videos
[8] Contacts

Enter your choice: 1,3,4
Selected folders: Documents, Pictures, Downloads

[Dry-Run] Would move Documents from C:\Users\Gerhard Wagner\Documents to D:\Gerhard\Documents
[Dry-Run] Would update registry Personal -> D:\Gerhard\Documents

[Dry-Run] Would move Pictures from C:\Users\Gerhard Wagner\Pictures to D:\Gerhard\Pictures
[Dry-Run] Would update registry My Pictures -> D:\Gerhard\Pictures

[Dry-Run] Would move Downloads from C:\Users\Gerhard Wagner\Downloads to D:\Gerhard\Downloads
[Dry-Run] Would update registry {374DE290-123F-4565-9164-39C4925E467B} -> D:\Gerhard\Downloads

Dry-Run finished. No changes were made.
=== Script Finished ===

