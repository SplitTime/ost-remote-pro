# Run from the project root: .\tool\run_tests.ps1

$suites = @(
    @{ file = "test/utils/time_utils_test.dart";                      label = "TimeUtils" },
    @{ file = "test/services/preferences_service_test.dart";          label = "PreferencesService" },
    @{ file = "test/services/raw_time_store_test.dart";               label = "RawTimeEntry & RawTimeStore" },
    @{ file = "test/services/cross_check_service_test.dart";          label = "CrossCheckService" },
    @{ file = "test/controllers/live_entry_controller_test.dart";     label = "LiveEntryController" },
    @{ file = "test/widgets/numpad_test.dart";                        label = "NumPad Widget" },
    @{ file = "test/widgets/two_state_toggle_test.dart";              label = "TwoStateToggle Widget" },
    @{ file = "test/widgets/clock_widget_test.dart";                  label = "ClockWidget" },
    @{ file = "test/pages/login_page_test.dart";                      label = "LoginPage" },
    @{ file = "test/pages/utilities_page_test.dart";                  label = "Utilities Page" },
    @{ file = "test/pages/cross_check_page_test.dart";                label = "CrossCheck Page" },
    @{ file = "test/pages/review_sync_page_test.dart";                label = "ReviewSync Page" },
    @{ file = "test/pages/live_entry_page_test.dart";                 label = "LiveEntry Page" }
)

$passed = 0
$failed = 0
$total  = $suites.Count

Write-Host ""
Write-Host "OST Remote Pro — Test Runner" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

foreach ($suite in $suites) {
    $i = $passed + $failed + 1
    Write-Host "[$i/$total] $($suite.label) ... " -NoNewline

    $out = flutter test $suite.file 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PASS" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "FAIL" -ForegroundColor Red
        $out -split "`n" | Where-Object { $_ -match "Expected:|Actual:|Error:" } |
            Select-Object -First 4 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkRed }
        $failed++
    }

    # Progress bar — each block printed individually so colours are correct
    $pct = [int](($passed + $failed) * 100 / $total)
    Write-Host "    [" -NoNewline
    for ($j = 1; $j -le $total; $j++) {
        if     ($j -le $passed)            { Write-Host "#" -NoNewline -ForegroundColor Green }
        elseif ($j -le ($passed + $failed)){ Write-Host "#" -NoNewline -ForegroundColor Red   }
        else                               { Write-Host "-" -NoNewline -ForegroundColor DarkGray }
    }
    Write-Host "]  $pct%"
    Write-Host ""
}

Write-Host "=============================" -ForegroundColor Cyan
Write-Host "Passed: $passed / $total" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
if ($failed -gt 0) {
    Write-Host "Failed: $failed" -ForegroundColor Red
    exit 1
}
