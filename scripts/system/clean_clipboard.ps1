# clean_clipboard.ps1 — Strip ANSI escape sequences from clipboard
# Usage: .\clean_clipboard.ps1
# After copying colored terminal output, run this to sanitize before pasting into Markdown/docs.

$text = Get-Clipboard -Raw -TextFormatType UnicodeText -ErrorAction Stop

# Remove ANSI escape sequences (CSI: ESC [ ... m)
$text = $text -replace "`e\[[0-9;]*m", ""

# Also catch any bare ESC characters
$text = $text -replace "`e", ""

Set-Clipboard -Value $text

Write-Host "Clipboard cleaned (ANSI escape sequences removed)." -ForegroundColor Green
