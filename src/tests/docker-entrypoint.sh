#!/usr/bin/env bash

set -u

echo "============================================================"
echo "  Simple Bash Utils — containerized test run"
echo "  Alpine $(cat /etc/alpine-release 2>/dev/null || echo unknown)"
echo "  gcc:     $(gcc --version | head -1)"
echo "  cat:     $(cat --version 2>/dev/null | head -1 || echo 'busybox')"
echo "  grep:    $(grep --version | head -1)"
echo "  busybox: $(busybox | head -1)"
echo "============================================================"
echo

echo "=== Building s21_cat ==="
cd /work/src/s21_cat
if [[ -f Makefile ]]; then
  make clean 2>/dev/null || true
  if ! make; then
    echo "ERROR: s21_cat build failed" >&2
    exit 2
  fi
else
  echo "No Makefile — building directly"
  gcc -Wall -Wextra -std=c11 -D_POSIX_C_SOURCE=200809L cat.c -o s21_cat || exit 2
fi
ls -la s21_cat
echo

echo "=== Building s21_grep ==="
cd /work/src/s21_grep
if [[ -f Makefile ]]; then
  make clean 2>/dev/null || true
  if ! make; then
    echo "ERROR: s21_grep build failed" >&2
    exit 2
  fi
else
  gcc -Wall -Wextra -std=c11 -D_POSIX_C_SOURCE=200809L grep.c -o s21_grep || exit 2
fi
ls -la s21_grep
echo

REF_CAT="${REF_CAT:-cat}"
REF_GREP="${REF_GREP:-grep}"
export CHECK_RC="${CHECK_RC:-1}"
export VERBOSE="${VERBOSE:-0}"

echo "=== Running test suite ==="
echo "cat reference:  $REF_CAT  ($(command -v "$REF_CAT"))"
echo "grep reference: $REF_GREP ($(command -v "$REF_GREP"))"
echo "CHECK_RC=$CHECK_RC VERBOSE=$VERBOSE"
echo

cd /work/src/tests

RC=0
REF_BIN="$REF_CAT"  bash test_cat.sh  || RC=1
echo
REF_BIN="$REF_GREP" bash test_grep.sh || RC=1

echo
if [[ $RC -eq 0 ]]; then
  echo "=== ALL SUITES PASSED ==="
else
  echo "=== SOME SUITES FAILED ==="
fi
exit $RC