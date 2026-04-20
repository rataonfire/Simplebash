#!/usr/bin/env bash
if [[ -t 1 ]]; then
  C_GREEN='\033[0;32m'
  C_RED='\033[0;31m'
  C_YELLOW='\033[0;33m'
  C_GRAY='\033[0;90m'
  C_RESET='\033[0m'
else
  C_GREEN='' C_RED='' C_YELLOW='' C_GRAY='' C_RESET=''
fi


TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
FAIL_LOG=""


VERBOSE="${VERBOSE:-0}"
SHOW_DIFF="${SHOW_DIFF:-1}"

CHECK_RC="${CHECK_RC:-1}"


run_case() {
  local desc="$1"
  local args="$2"

  local my_out ref_out my_rc ref_rc
  my_out=$(eval "$MY_BIN $args" 2>/dev/null)
  my_rc=$?
  ref_out=$(eval "$REF_BIN $args" 2>/dev/null)
  ref_rc=$?


  local rc_match=1
  if [[ "$CHECK_RC" == "1" ]]; then
    if [[ $my_rc -eq 0 && $ref_rc -ne 0 ]] || [[ $my_rc -ne 0 && $ref_rc -eq 0 ]]; then
      rc_match=0
    fi
  fi

  if [[ "$my_out" == "$ref_out" && $rc_match -eq 1 ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    [[ "$VERBOSE" == "1" ]] && printf "${C_GREEN}PASS${C_RESET} %s\n" "$desc"
    return 0
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    printf "${C_RED}FAIL${C_RESET} %s\n" "$desc"
    printf "  ${C_GRAY}args:${C_RESET} %s\n" "$args"
    printf "  ${C_GRAY}my  rc=%d, ref rc=%d${C_RESET}\n" "$my_rc" "$ref_rc"
    if [[ "$SHOW_DIFF" == "1" ]]; then
      diff <(printf '%s' "$my_out") <(printf '%s' "$ref_out") \
        | sed 's/^/    /' \
        | head -20
    fi
    return 1
  fi
}

skip_case() {
  TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
  printf "${C_YELLOW}SKIP${C_RESET} %s — %s\n" "$1" "$2"
}


print_summary() {
  local total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
  echo
  echo "=============================================="
  printf "Total:   %d\n" "$total"
  printf "${C_GREEN}Passed:  %d${C_RESET}\n" "$TESTS_PASSED"
  printf "${C_RED}Failed:  %d${C_RESET}\n" "$TESTS_FAILED"
  if [[ $TESTS_SKIPPED -gt 0 ]]; then
    printf "${C_YELLOW}Skipped: %d${C_RESET}\n" "$TESTS_SKIPPED"
  fi
  echo "=============================================="
  [[ $TESTS_FAILED -eq 0 ]]
}

require_bin() {
  if [[ ! -x "$1" ]]; then
    printf "${C_RED}ERROR${C_RESET}: %s not found or not executable\n" "$1" >&2
    exit 2
  fi
}

setup_fixtures() {
  cat > simple.txt <<'EOF'
first line
second line
third line
EOF


  cat > blanks.txt <<'EOF'
hello


world



end
EOF
  : > empty.txt


  printf "no trailing newline" > no_newline.txt


  printf "col1\tcol2\tcol3\nfoo\tbar\tbaz\n" > tabs.txt

  printf "normal\n\x01\x02ctrl\n\x7fdel\n" > ctrl.txt

  cat > mixed.txt <<'EOF'
The quick brown fox
jumps over the lazy dog
THE QUICK BROWN FOX
Hello, World!
Foo bar baz
123 numbers 456
EOF


  cat > other.txt <<'EOF'
another file
with the word fox
and some numbers 789
EOF


  cat > patterns.txt <<'EOF'
fox
numbers
EOF


  : > empty_patterns.txt
}
