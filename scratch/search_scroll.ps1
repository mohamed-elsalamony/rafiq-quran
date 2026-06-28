$filePath = "lib\features\quran\presentation\quran_screen.dart"
$lines = Get-Content $filePath
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match "scroll" -or $lines[$i] -match "Scroll" -or $lines[$i] -match "animateTo" -or $lines[$i] -match "jumpTo") {
        Write-Host "$($i + 1): $($lines[$i])"
    }
}
