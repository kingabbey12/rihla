#!/usr/bin/env bash
# Sprint 1 interactive macOS verification — captures real window screenshots
# and drives the launch flow via System Events clicks.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/verification_screenshots/macos"
BUNDLE="com.example.rihla"
LOG="$OUT/flutter_run.log"
mkdir -p "$OUT"

echo "==> Resetting launch preferences"
defaults delete "$BUNDLE" 2>/dev/null || true
rm -f "$HOME/Library/Preferences/${BUNDLE}.plist" 2>/dev/null || true

capture() {
  local name="$1"
  local path="$OUT/${name}.png"
  local wid
  wid=$(osascript -e 'tell application "System Events" to tell process "rihla" to get id of window 1' 2>/dev/null || echo "")
  if [[ -n "$wid" ]]; then
    screencapture -x -l"$wid" "$path" 2>/dev/null || screencapture -x "$path" 2>/dev/null || true
  else
    screencapture -x "$path" 2>/dev/null || true
  fi
  if [[ -f "$path" ]]; then
    echo "  captured: $name"
  else
    echo "  WARN: failed capture $name"
  fi
}

back_to_home() {
  click_relative 0.06 0.05
  sleep 1.2
}

click_relative() {
  # x and y are fractions 0..1 of window size
  local x_frac="$1"
  local y_frac="$2"
  osascript <<APPLESCRIPT
tell application "System Events"
  tell process "rihla"
    set frontmost to true
    set win to window 1
    set {wx, wy} to position of win
    set {ww, wh} to size of win
    set cx to (wx + (ww * $x_frac)) as integer
    set cy to (wy + (wh * $y_frac)) as integer
    click at {cx, cy}
  end tell
end tell
APPLESCRIPT
}

wait_for_app() {
  local i=0
  while [[ $i -lt 90 ]]; do
    if osascript -e 'tell application "System Events" to return exists process "rihla"' 2>/dev/null | grep -q true; then
      return 0
    fi
    sleep 2
    i=$((i + 1))
  done
  return 1
}

echo "==> Starting flutter run -d macos (log: $LOG)"
cd "$ROOT"
flutter run -d macos --no-pub 2>&1 | tee "$LOG" &
RUN_PID=$!

cleanup() {
  kill "$RUN_PID" 2>/dev/null || true
  pkill -f "build/macos/Build/Products/Debug/rihla.app" 2>/dev/null || true
}
trap cleanup EXIT

echo "==> Waiting for rihla process"
wait_for_app || { echo "App did not launch in time"; exit 1; }
sleep 3

echo "==> 1. Splash screen"
capture "01_splash"
sleep 2

echo "==> 2. Brand splash"
capture "02_brand_splash"
sleep 4

echo "==> 3. Welcome screen"
capture "03_welcome"
click_relative 0.5 0.72   # Get Started
sleep 2

echo "==> 4. Onboarding"
capture "04_onboarding_1"
click_relative 0.5 0.88   # Next
sleep 1
capture "05_onboarding_2"
click_relative 0.5 0.88
sleep 1
capture "06_onboarding_3"
click_relative 0.5 0.88
sleep 1
capture "07_onboarding_4"
click_relative 0.5 0.88   # Start My Journey
sleep 2

echo "==> 5. Permissions (5 steps — Not now)"
for i in 1 2 3 4 5; do
  capture "08_permissions_${i}"
  click_relative 0.5 0.90
  sleep 1.5
done
sleep 2

echo "==> 6. Authentication"
capture "09_authentication"
click_relative 0.5 0.78   # Continue as Guest
sleep 5

echo "==> 7-11. AI Home Dashboard"
capture "10_home_dashboard"
sleep 2
capture "11_home_dashboard_settled"

echo "==> 12. Explore"
click_relative 0.38 0.95
sleep 2
capture "12_explore"
back_to_home

echo "==> 13. Emergency"
click_relative 0.62 0.95
sleep 2
capture "13_emergency"
back_to_home

echo "==> 14. Profile"
click_relative 0.85 0.95
sleep 2
capture "14_profile"

echo "==> Scanning log for exceptions"
if rg -i "exception|overflow|error|red screen|failed assertion" "$LOG" | rg -v "debug|info|Warning:.*overflowed by 0" | head -20; then
  echo "WARN: possible issues in log (review above)"
else
  echo "No critical exceptions detected in flutter run log"
fi

echo "==> Done. Screenshots in $OUT"
