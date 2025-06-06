Add-Type -AssemblyName System.Windows.Forms
$nl = [Environment]::NewLine
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
$notifyIcon.BalloonTipTitle = "AutoExtractor v1.0"
$notifyIcon.BalloonTipText = "Recursively extracts .zip, .rar, and .gz files. Supports batch processing.${nl}By Vinay Raj Choudhary${nl}05 June 2025"
$notifyIcon.Visible = $true
$notifyIcon.ShowBalloonTip(500)

Start-Sleep -Milliseconds 600
$notifyIcon.Dispose()


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$WinRAR = "C:\Program Files\WinRAR\WinRAR.exe"
#$logPath = "$env:USERPROFILE\Downloads\AutoExtractor.log"

function Log {
    param([string]$message)
    #$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    #"[$timestamp] $message" | Out-File -Append $logPath
}

function Extract-Archive {
    param (
        [string]$filePath,
        [string]$destination
    )

    $ext = [System.IO.Path]::GetExtension($filePath).ToLower()

    if ($ext -eq ".zip") {
        try {
            Expand-Archive -Path $filePath -DestinationPath $destination -Force
            Log "✅ Unzipped ZIP: ${filePath} → ${destination}"
        } catch {
            Log "❌ Failed to unzip ${filePath}: $($_.Exception.Message)"
        }
    }
    elseif ($ext -eq ".rar") {
        if (Test-Path $WinRAR) {
            try {
                & "$WinRAR" x -ibck -o+ "$filePath" "$destination\" | Out-Null
                Log "✅ Extracted RAR: ${filePath} → ${destination}"
            } catch {
                Log "❌ Failed to extract RAR ${filePath}: $($_.Exception.Message)"
            }
        } else {
            Log "❌ WinRAR not found at $WinRAR"
        }
    }
    elseif ($ext -eq ".gz") {
        $outputFile = Join-Path ([System.IO.Path]::GetDirectoryName($filePath)) ([System.IO.Path]::GetFileNameWithoutExtension($filePath))
        try {
            $inputFileStream = [System.IO.File]::OpenRead($filePath)
            $outputFileStream = [System.IO.File]::Create($outputFile)
            $gzipStream = New-Object System.IO.Compression.GzipStream($inputFileStream, [System.IO.Compression.CompressionMode]::Decompress)

            $buffer = New-Object byte[] 4096
            while (($read = $gzipStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $outputFileStream.Write($buffer, 0, $read)
            }

            $gzipStream.Close()
            $inputFileStream.Close()
            $outputFileStream.Close()

            Log "✅ Decompressed GZ: ${filePath} → ${outputFile}"
        } catch {
            Log "❌ Failed to decompress GZ ${filePath}: $($_.Exception.Message)"
        }
    }
    else {
        Log "⚠️ Unsupported archive type: ${filePath}"
    }
}

function Unzip-WithNestedArchives {
    param (
        [string]$archivePath,
        [string]$destination
    )

    Extract-Archive -filePath $archivePath -destination $destination

    $nested = Get-ChildItem -Path $destination -Recurse -Include *.zip, *.rar, *.gz
    foreach ($archive in $nested) {
        $nestedDest = "$($archive.DirectoryName)\$($archive.BaseName)-unzipped"
        Extract-Archive -filePath $archive.FullName -destination $nestedDest
    }
}

# File picker dialog
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.InitialDirectory = [System.IO.Path]::Combine($env:USERPROFILE, "Downloads")
$dialog.Multiselect = $true
$dialog.Filter = "Archives (*.zip;*.rar;*.gz)|*.zip;*.rar;*.gz|All files (*.*)|*.*"

$dialog.Multiselect = $true
$dialog.Filter = "Archives (*.zip;*.rar;*.gz)|*.zip;*.rar;*.gz|All files (*.*)|*.*"

if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    foreach ($file in $dialog.FileNames) {
        $ext = [System.IO.Path]::GetExtension($file).ToLower()
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
        $targetFolder = Join-Path ([System.IO.Path]::GetDirectoryName($file)) "$baseName-unzipped"

        switch ($ext) {
            ".zip" { Unzip-WithNestedArchives -archivePath $file -destination $targetFolder }
            ".rar" { Extract-Archive -filePath $file -destination $targetFolder }
            ".gz"  { Extract-Archive -filePath $file -destination $null }
            default { Log "ℹ️ Skipped unsupported file: ${file}" }
        }
    }
} else {
    Log "❌ No files selected for extraction."
}
