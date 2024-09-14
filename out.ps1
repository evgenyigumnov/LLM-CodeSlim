# Remove existing out.txt if it exists
if (Test-Path -Path "out.txt") {
    Remove-Item -Path "out.txt" -Force
}

# Define arrays

# Folders and files to ignore during the search
$foldersToIgnore = @("target", ".git", ".github", ".gitignore", ".idea")

# File extensions to search for
$extensionsToSearch = @("rs")

# Specific filenames to search for
$filenamesToSearch = @("Cargo.toml", "core.rs", "text.rs", "json.rs")

# Characters that denote comments in the files
$commentChars = @("#", "//", "/*")

# Words that, when encountered, will stop processing the current file
$stopWords = @("#[cfg(test)]")

# Function to build file filtering based on provided criteria
function Get-FilteredFiles {
    param (
        [string[]]$IgnoreFolders,
        [string[]]$Extensions,
        [string[]]$Filenames
    )

    # Build a regex pattern for ignored folders
    if ($IgnoreFolders.Count -gt 0) {
        $ignorePattern = ($IgnoreFolders | ForEach-Object { [regex]::Escape($_) }) -join '|'
    } else {
        $ignorePattern = ""
    }

    # Build a list of filters for extensions and filenames
    $nameFilters = @()
    foreach ($ext in $Extensions) {
        $nameFilters += "*.$ext"
    }
    foreach ($fname in $Filenames) {
        $nameFilters += $fname
    }

    # Get all files with the specified extensions or filenames
    Get-ChildItem -Path . -Recurse -File -Include $nameFilters | Where-Object {
        if ($ignorePattern) {
            # Check if the full path contains any of the ignored folders
            -not ($_.FullName -match "\\($ignorePattern)\\")
        } else {
            $true
        }
    }
}

# Build a regex pattern for comments
$escapedCommentChars = $commentChars | ForEach-Object { [regex]::Escape($_) }
$commentPattern = $escapedCommentChars -join '|'

# Get the list of files to process
$files = Get-FilteredFiles -IgnoreFolders $foldersToIgnore -Extensions $extensionsToSearch -Filenames $filenamesToSearch

# Process each file
foreach ($file in $files) {
    # Add file header to out.txt
    "`n#### $($file.FullName) ####" | Out-File -FilePath "out.txt" -Append -Encoding utf8

    $stop = $false

    # Read the file line by line
    Get-Content -Path $file.FullName | ForEach-Object {
        if ($stop) {
            return
        }

        $line = $_

        # Remove tabs
        $line = $line -replace "`t", ""

        # Trim leading and trailing spaces
        $line = $line.Trim()

        # Skip empty lines
        if ([string]::IsNullOrWhiteSpace($line)) {
            return
        }

        # Check for stop words
        foreach ($stopWord in $stopWords) {
            if ($line -eq $stopWord) {
                $stop = $true
                break
            }
        }
        if ($stop) {
            return
        }

        # Skip lines that are comments
        if ($line -match "^($commentPattern)") {
            return
        }

        # Write the processed line to out.txt
        $line | Out-File -FilePath "out.txt" -Append -Encoding utf8
    }
}
