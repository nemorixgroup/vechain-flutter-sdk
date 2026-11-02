#!/usr/bin/env bash
# pre_commit.sh
# Run this before every commit. Must exit 0 before pushing.

set -e

echo -e "\033[0;36m==> Getting dependencies...\033[0m"
flutter pub get

echo -e "\033[0;36m==> Checking formatting...\033[0m"
dart format --output=none --set-exit-if-changed . || {
    echo -e "\033[0;31mFormatting issues found. Run 'dart format .' to fix.\033[0m"
    exit 1
}

echo -e "\033[0;36m==> Running static analysis...\033[0m"
flutter analyze --fatal-infos

# Unit tests: offline, mirror lib/src/ under test/src/.
if [ -n "$(find test/src -name '*_test.dart' 2>/dev/null)" ]; then
    echo -e "\033[0;36m==> Running unit tests with coverage...\033[0m"
    flutter test test/src --coverage
else
    echo -e "\033[0;33m==> No unit tests yet, skipping.\033[0m"
fi

# Integration tests: real network calls against the VeChain testnet.
if [ -n "$(find test/integration -name '*_test.dart' 2>/dev/null)" ]; then
    echo -e "\033[0;36m==> Running integration tests...\033[0m"
    flutter test test/integration --concurrency=1
else
    echo -e "\033[0;33m==> No integration tests yet, skipping.\033[0m"
fi

echo ""
echo -e "\033[0;32mAll checks passed. Safe to commit.\033[0m"
