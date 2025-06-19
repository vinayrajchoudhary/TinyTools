Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$nl = [Environment]::NewLine

# Show balloon notification
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
$notifyIcon.BalloonTipTitle = "PDFExtractor v1.0"
$notifyIcon.BalloonTipText = "Recursively extracts .zip, .rar, and .gz files${nl}Collects all PDFs to a single folder${nl}By Vinay Raj Choudhary — 19 June 2025"
$notifyIcon.Visible = $true
$notifyIcon.ShowBalloonTip(500)
Start-Sleep -Milliseconds 600
$notifyIcon.Dispose()

# Set WinRAR path (for .rar extraction)
$WinRAR = "C:\Program Files\WinRAR\WinRAR.exe"

function Extract-Archive {
    param (
        [string]$filePath,
        [string]$destination
    )

    $ext = [System.IO.Path]::GetExtension($filePath).ToLower()

    if ($ext -eq ".zip") {
        try {
            Expand-Archive -Path $filePath -DestinationPath $destination -Force
        } catch {}
    }
    elseif ($ext -eq ".rar") {
        if (Test-Path $WinRAR) {
            try {
                & "$WinRAR" x -ibck -o+ "$filePath" "$destination\" | Out-Null
            } catch {}
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
        } catch {}
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

# 1. Ask user to select input archive files
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.InitialDirectory = [System.IO.Path]::Combine($env:USERPROFILE, "Downloads")
$dialog.Multiselect = $true
$dialog.Filter = "Archives (*.zip;*.rar;*.gz)|*.zip;*.rar;*.gz|All files (*.*)|*.*"

if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    # 2. Ask user to select output folder for PDFs
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select a folder to save all extracted PDF files"
    $folderDialog.SelectedPath = [System.IO.Path]::Combine($env:USERPROFILE, "Downloads")

    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $pdfOutputFolder = $folderDialog.SelectedPath
        $tempFolders = @()

        foreach ($file in $dialog.FileNames) {
            $ext = [System.IO.Path]::GetExtension($file).ToLower()
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)
            $targetFolder = Join-Path ([System.IO.Path]::GetDirectoryName($file)) "$baseName-unzipped"

            # Extract based on type
            switch ($ext) {
                ".zip" { Unzip-WithNestedArchives -archivePath $file -destination $targetFolder }
                ".rar" { Extract-Archive -filePath $file -destination $targetFolder }
                ".gz"  { Extract-Archive -filePath $file -destination $null }
            }

            # Collect folder for cleanup
            if (Test-Path $targetFolder) {
                $tempFolders += $targetFolder
            }
        }

        # 3. Find all PDFs and copy to the selected output folder
        foreach ($folder in $tempFolders) {
            $pdfs = Get-ChildItem -Path $folder -Recurse -Include *.pdf -ErrorAction SilentlyContinue
            foreach ($pdf in $pdfs) {
                $destFile = Join-Path $pdfOutputFolder $pdf.Name
                try {
                    Copy-Item -Path $pdf.FullName -Destination $destFile -Force
                } catch {}
            }
        }

        # 4. Clean up all temporary extraction folders
        foreach ($folder in $tempFolders) {
            try {
                Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            } catch {}
        }
	# Step 5: Open the output folder
	Start-Process -FilePath $pdfOutputFolder

    }
}
