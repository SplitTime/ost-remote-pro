# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Counters
PASSED_SUITES=0
FAILED_SUITES=0
FAILED_FILES=()
MAX_SUITES=0

# Parse arguments
MODE="all"
COVERAGE=false
for arg in "$@"; do
  case $arg in
    --unit)     MODE="unit" ;;
    --widget)   MODE="widget" ;;
    --all)      MODE="all" ;;
    --coverage) COVERAGE=true ;;
  esac
done

# Set max suites based on mode
case $MODE in
  unit)   MAX_SUITES=5 ;;
  widget) MAX_SUITES=8 ;;
  all)    MAX_SUITES=13 ;;
esac


print_header() {
  echo ""
  echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${BLUE}║           OST Remote Pro - Test Suite Runner               ║${NC}"
  echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${CYAN}Mode:${NC} ${BOLD}$MODE${NC}   ${CYAN}Suites:${NC} ${BOLD}$MAX_SUITES${NC}   ${CYAN}Date:${NC} ${BOLD}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
  echo ""
}

print_section() {
  echo ""
  echo -e "${BOLD}${YELLOW}┌──────────────────────────────────────────────────────────┐${NC}"
  echo -e "${BOLD}${YELLOW}│  $1${NC}"
  echo -e "${BOLD}${YELLOW}└──────────────────────────────────────────────────────────┘${NC}"
  echo ""
}

# Draw a green/red/gray progress bar.
# Each character = one test suite:  green █ = passed, red █ = failed, gray ░ = pending.
draw_progress_bar() {
  local passed=$1
  local failed=$2
  local total=$3
  local completed=$(( passed + failed ))
  local pct=0
  if [ "$total" -gt 0 ]; then
    pct=$(( (completed * 100) / total ))
  fi

  printf "  ["
  for ((i = 1; i <= total; i++)); do
    if   [ $i -le "$passed" ]; then
      printf "${GREEN}█${NC}"
    elif [ $i -le "$(( passed + failed ))" ]; then
      printf "${RED}█${NC}"
    else
      printf "${GRAY}░${NC}"
    fi
  done
  printf "]  %3d%%  (%d/%d suites)\n" "$pct" "$completed" "$total"
}

# ============================================================================
# Test Runner
# ============================================================================

run_test_file() {
  local file=$1
  local label=$2

  echo -e "  ${CYAN}▶${NC} ${BOLD}$label${NC}"

  # Run once; the `if` construct captures exit code without triggering errexit.
  local output
  if output=$(flutter test "$file" --reporter expanded 2>&1); then
    # Count individual tests from flutter output (e.g. "+5: All tests passed!")
    local test_count
    test_count=$(echo "$output" | grep -oE '^\+([0-9]+)' | tail -1 | tr -d '+')
    local count_str=""
    if [ -n "$test_count" ]; then
      count_str=" (${test_count} tests)"
    fi
    echo -e "  ${GREEN}✓ PASSED${NC}: $label${GRAY}${count_str}${NC}"
    PASSED_SUITES=$(( PASSED_SUITES + 1 ))
  else
    echo -e "  ${RED}✗ FAILED${NC}: $label"
    FAILED_SUITES=$(( FAILED_SUITES + 1 ))
    FAILED_FILES+=("$file")
    # Print the most relevant failure lines for quick TDD feedback.
    echo "$output" \
      | grep -E "(Expected:|Actual:|✗ |FAILED|Error:|package:)" \
      | head -8 \
      | sed 's/^/      /'
  fi

  echo ""
  draw_progress_bar "$PASSED_SUITES" "$FAILED_SUITES" "$MAX_SUITES"
  echo ""
}

# ============================================================================
# Summary
# ============================================================================

print_summary() {
  echo ""
  echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${BLUE}║                     TEST SUMMARY                          ║${NC}"
  echo -e "${BOLD}${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
  printf "${BOLD}${BLUE}║${NC}  %-20s  ${BOLD}%d${NC}\n" "Total suites:" "$MAX_SUITES"
  printf "${GREEN}${BOLD}║${NC}  ${GREEN}%-20s  ${BOLD}%d${NC}\n" "Passed:" "$PASSED_SUITES"
  if [ "$FAILED_SUITES" -gt 0 ]; then
    printf "${RED}${BOLD}║${NC}  ${RED}%-20s  ${BOLD}%d${NC}\n" "Failed:" "$FAILED_SUITES"
    echo -e "${BOLD}${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${RED}Failed suites:${NC}"
    for f in "${FAILED_FILES[@]}"; do
      echo -e "${BOLD}${BLUE}║${NC}    ${RED}• $f${NC}"
    done
  else
    printf "${BOLD}${BLUE}║${NC}  ${GREEN}%-20s  ${BOLD}%d${NC}\n" "Failed:" "0"
  fi
  echo -e "${BOLD}${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
  printf "${BOLD}${BLUE}║${NC}  "
  draw_progress_bar "$PASSED_SUITES" "$FAILED_SUITES" "$MAX_SUITES"
  echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  if [ "$FAILED_SUITES" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}ALL TESTS PASSED!${NC}"
    echo ""
  else
    echo -e "  ${RED}${BOLD}SOME TESTS FAILED — review the output above${NC}"
    echo ""
    exit 1
  fi
}

# ============================================================================
# Main
# ============================================================================

print_header

# --- Unit Tests ---
if [ "$MODE" = "unit" ] || [ "$MODE" = "all" ]; then
  print_section "UNIT TESTS"
  run_test_file "test/utils/time_utils_test.dart"                        "TimeUtils"
  run_test_file "test/services/preferences_service_test.dart"            "PreferencesService"
  run_test_file "test/services/raw_time_store_test.dart"                 "RawTimeEntry & RawTimeStore"
  run_test_file "test/services/cross_check_service_test.dart"            "CrossCheckService & ViewModel"
  run_test_file "test/controllers/live_entry_controller_test.dart"       "LiveEntryController"
fi

# --- Widget Tests ---
if [ "$MODE" = "widget" ] || [ "$MODE" = "all" ]; then
  print_section "WIDGET TESTS"
  run_test_file "test/widgets/numpad_test.dart"              "NumPad Widget"
  run_test_file "test/widgets/two_state_toggle_test.dart"    "TwoStateToggle Widget"
  run_test_file "test/widgets/clock_widget_test.dart"        "ClockWidget"
  run_test_file "test/pages/login_page_test.dart"            "LoginPage"
  run_test_file "test/pages/utilities_page_test.dart"        "Utilities Page"
  run_test_file "test/pages/cross_check_page_test.dart"      "CrossCheck Page"
  run_test_file "test/pages/review_sync_page_test.dart"      "ReviewSync Page"
  run_test_file "test/pages/live_entry_page_test.dart"       "LiveEntry Page"
fi

# --- Coverage ---
if [ "$COVERAGE" = true ]; then
  print_section "COVERAGE REPORT"
  echo -e "  ${CYAN}Generating coverage...${NC}"
  flutter test --coverage
  echo -e "  ${GREEN}✓${NC} Coverage report at ${BOLD}coverage/lcov.info${NC}"
fi

print_summary
