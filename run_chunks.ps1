$total = 24479
$mdPath = "C:\Users\Laptop\.gemini\antigravity\brain\0deb0a4e-f7c7-424e-9120-5f5dfeea3a8a\verify_results.md"

"# Verification Run - Post-Fix" | Set-Content $mdPath

for ($i = 1000; $i -lt $total; $i += 1000) {
    $end = [math]::Min($i + 999, $total - 1)
    Write-Host "Running chunk $i to $end..."
    $env:QUANTUM_START_INDEX = $i
    $env:QUANTUM_END_INDEX = $end

    $logFile = "verify_$i.log"
    flutter test test/template_layout_test_corpus/main_test.dart > $logFile 2>&1

    $failures = Select-String -Path $logFile -Pattern "failed with \d+ issue\(s\)"
    $passed   = Select-String -Path $logFile -Pattern "All tests passed"

    if ($passed) {
        Add-Content -Path $mdPath -Value ""
        Add-Content -Path $mdPath -Value "## Chunk $i - $end : ALL PASSED"
        Write-Host "  PASSED"
    } else {
        $count = $failures.Count
        $sample = if ($failures.Count -gt 0) { $failures[0].Line.Trim() } else { "see $logFile" }
        Add-Content -Path $mdPath -Value ""
        Add-Content -Path $mdPath -Value "## Chunk $i - $end : FAILED ($count failures)"
        Add-Content -Path $mdPath -Value "- Sample: $sample"
        Write-Host "  FAILED: $count failures"
    }
}
Write-Host "All verification chunks finished!"
