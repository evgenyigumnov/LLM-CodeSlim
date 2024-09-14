# out.ps1

# Удаляем существующий out.txt, если он есть
if (Test-Path -Path "out.txt") {
    Remove-Item -Path "out.txt" -Force
}

# Определяем массивы
$foldersToIgnore = @("target", ".git", ".github", ".gitignore", ".idea")
$extensionsToSearch = @("rs")
$filenamesToSearch = @("Cargo.toml", "core.rs", "text.rs", "json.rs")
$commentChars = @("#", "//", "/*")
$stopWords = @("#[cfg(test)]")

# Функция для построения фильтрации путей
function Get-FilteredFiles {
    param (
        [string[]]$IgnoreFolders,
        [string[]]$Extensions,
        [string[]]$Filenames
    )

    # Строим регулярное выражение для игнорируемых папок
    if ($IgnoreFolders.Count -gt 0) {
        $ignorePattern = ($IgnoreFolders | ForEach-Object { [regex]::Escape($_) }) -join '|'
    } else {
        $ignorePattern = ""
    }

    # Строим список фильтров для расширений и имен файлов
    $nameFilters = @()
    foreach ($ext in $Extensions) {
        $nameFilters += "*.$ext"
    }
    foreach ($fname in $Filenames) {
        $nameFilters += $fname
    }

    # Получаем все файлы с заданными расширениями или именами
    Get-ChildItem -Path . -Recurse -File -Include $nameFilters | Where-Object {
        if ($ignorePattern) {
            # Проверяем, содержит ли полный путь одну из игнорируемых папок
            -not ($_.FullName -match "\\($ignorePattern)\\")
        } else {
            $true
        }
    }
}

# Строим регулярное выражение для комментариев
$escapedCommentChars = $commentChars | ForEach-Object { [regex]::Escape($_) }
$commentPattern = $escapedCommentChars -join '|'

# Получаем список файлов
$files = Get-FilteredFiles -IgnoreFolders $foldersToIgnore -Extensions $extensionsToSearch -Filenames $filenamesToSearch

# Обрабатываем каждый файл
foreach ($file in $files) {
    # Добавляем заголовок файла в out.txt
    "`n#### $($file.FullName) ####" | Out-File -FilePath "out.txt" -Append -Encoding utf8

    $stop = $false

    # Читаем файл построчно
    Get-Content -Path $file.FullName | ForEach-Object {
        if ($stop) {
            return
        }

        $line = $_

        # Удаляем табуляции
        $line = $line -replace "`t", ""

        # Удаляем ведущие и конечные пробелы
        $line = $line.Trim()

        # Пропускаем пустые строки
        if ([string]::IsNullOrWhiteSpace($line)) {
            return
        }

        # Проверяем на стоп-слова
        foreach ($stopWord in $stopWords) {
            if ($line -eq $stopWord) {
                $stop = $true
                break
            }
        }
        if ($stop) {
            return
        }

        # Пропускаем строки, являющиеся комментариями
        if ($line -match "^($commentPattern)") {
            return
        }

        # Записываем обработанную строку в out.txt
        $line | Out-File -FilePath "out.txt" -Append -Encoding utf8
    }
}
