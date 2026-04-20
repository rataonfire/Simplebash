#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET="${1:-all}"
OVERALL_RC=0

run_suite() {
  local name="$1"
  local script="$SCRIPT_DIR/test_$name.sh"
  echo
  echo "============================================================"
  echo "  Running $name suite"
  echo "============================================================"
  if bash "$script"; then
    echo "[$name] ALL PASSED"
  else
    echo "[$name] FAILURES"
    OVERALL_RC=1
  fi
}

case "$TARGET" in
  cat)  run_suite cat  ;;
  grep) run_suite grep ;;
  all)  run_suite cat; run_suite grep ;;
  *)    echo "usage: $0 [cat|grep|all]" >&2; exit 2 ;;
esac

echo
if [[ $OVERALL_RC -eq 0 ]]; then
  echo "=== ALL SUITES PASSED ==="
else
  echo "=== SOME SUITES FAILED ==="
fi
exit $OVERALL_RC
