# pre_commit.ps1
# Run this before every commit. Must be green (exit code 0) before pushing.

$ErrorActionPreference = "Stop"

Write-Host "==> Getting dependencies..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "pub get failed" -ForegroundColor Red; exit 1 }

Write-Host "==> Checking formatting..." -ForegroundColor Cyan
dart format --output=none --set-exit-if-changed .
if ($LASTEXITCODE -ne 0) {
    Write-Host "Formatting issues found. Run 'dart format .' to fix." -ForegroundColor Red
    exit 1
}

Write-Host "==> Running static analysis..." -ForegroundColor Cyan
flutter analyze --fatal-infos
if ($LASTEXITCODE -ne 0) { Write-Host "Analysis failed" -ForegroundColor Red; exit 1 }

# Unit tests: offline, mirror lib/src/ under test/src/.
$unitTests = Get-ChildItem -Path test/src -Recurse -Filter *_test.dart -ErrorAction SilentlyContinue
if ($unitTests) {
    Write-Host "==> Running unit tests with coverage..." -ForegroundColor Cyan
    flutter test test/src --coverage
    if ($LASTEXITCODE -ne 0) { Write-Host "Unit tests failed" -ForegroundColor Red; exit 1 }
} else {
    Write-Host "==> No unit tests yet, skipping." -ForegroundColor Yellow
}

# Integration tests: real network calls against the VeChain testnet.
$integrationTests = Get-ChildItem -Path test/integration -Recurse -Filter *_test.dart -ErrorAction SilentlyContinue
if ($integrationTests) {
    Write-Host "==> Running integration tests..." -ForegroundColor Cyan
    flutter test test/integration --concurrency=1
    if ($LASTEXITCODE -ne 0) { Write-Host "Integration tests failed" -ForegroundColor Red; exit 1 }
} else {
    Write-Host "==> No integration tests yet, skipping." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "All checks passed. Safe to commit." -ForegroundColor Green
