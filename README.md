
# AutoExtractor v1.0

**Author:** Vinay Raj Choudhary
**Date:** 05 June 2025

---

## Overview

AutoExtractor is a lightweight PowerShell-based utility designed to simplify the extraction of compressed archive files on Windows. It supports `.zip`, `.rar`, and `.gz` file formats and recursively extracts nested archives within these files. The program supports batch processing, allowing multiple archives to be selected and extracted in one operation.

Upon launch, AutoExtractor presents a user-friendly file selection dialog to choose one or more archive files. It then extracts each selected archive to a dedicated folder named after the archive with a `-unzipped` suffix, preserving the original folder structure. For `.rar` files, it relies on the presence of WinRAR at the default installation path. `.gz` files are decompressed directly using built-in .NET compression streams.

A brief informational balloon tip appears when the program starts, displaying version info and author credits.

---

## Features

* Recursive extraction of `.zip`, `.rar`, and `.gz` archives, including nested archives.
* Batch processing: select and extract multiple archives in a single run.
* Uses native PowerShell `Expand-Archive` for `.zip` files.
* Uses WinRAR command-line (if installed) for `.rar` extraction.
* Native .NET decompression of `.gz` files.
* Minimal dependencies, no complex installation required (except WinRAR for `.rar`).
* User-friendly file selection dialog on launch.
* Lightweight balloon tip notification on startup.

---

## Requirements

* Windows OS with PowerShell 5.1 or higher.
* WinRAR installed at `C:\Program Files\WinRAR\WinRAR.exe` for `.rar` support.
* No administrator privileges required.

---

## Usage

1. Run the executable or PowerShell script.
2. Select one or more archive files from the file picker dialog.
3. Extraction folders with suffix `-unzipped` are created alongside each archive.
4. Extraction completes and the program exits.

---

## Notes

* Ensure WinRAR is installed to enable `.rar` extraction; otherwise `.rar` files will be skipped.
* The program does not generate logs in the current version.
* Balloon tip notification briefly displays on startup and then disappears.
* If running on another machine, ensure WinRAR is installed or update the script path accordingly.
* `.gz` files are decompressed in place without a new folder suffix.
* Nested archives inside extracted folders are automatically processed recursively.

---

## Troubleshooting

* **Script execution policy blocked?** Run PowerShell as admin and use:

  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```
* **WinRAR not found?** Install WinRAR or change the `$WinRAR` path variable in the script to the correct location.
* **Unsupported files are skipped** silently (e.g., `.7z`, `.tar` not supported).
* Extraction folders will appear in the same directory as the archives; check there if extraction seems silent.

---

## Building the EXE from the PowerShell Script

To create a standalone executable from the PowerShell script, you can use the [`ps2exe`](https://github.com/MScholtes/PS2EXE) utility, which converts `.ps1` scripts into `.exe` files.

### Steps to build the EXE:

1. Download the latest **PS2EXE** release from the official GitHub repo:
   [https://github.com/MScholtes/PS2EXE](https://github.com/MScholtes/PS2EXE)

2. Extract the downloaded ZIP file. Locate the `ps2exe.ps1` script (usually under the `Module` folder).

3. Open PowerShell with the execution policy temporarily bypassed:

   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```

4. Run the conversion command (adjust paths accordingly):

   ```powershell
   powershell.exe -File "C:\path\to\ps2exe.ps1" -inputFile "AutoExtractor.ps1" -outputFile "AutoExtractor.exe" -noConsole -icon "app.ico"
   ```

   * `-noConsole` hides the PowerShell console window during execution.
   * `-icon` is optional, specify a custom icon if desired.

5. The generated `AutoExtractor.exe` can be run directly on compatible Windows machines.

---

## Future Enhancements / Known Limitations

* Support for more archive formats like `.7z` or `.tar`.
* Optional logging to file for detailed diagnostics.
* Silent/background operation mode (currently requires user interaction).
* Handling password-protected archives.
* Multiple instance detection to prevent concurrent runs.
* User-configurable WinRAR path via UI or config file.

---

## Credits

Developed by **Vinay Raj Choudhary**
Version 1.0 — June 5, 2025

---

