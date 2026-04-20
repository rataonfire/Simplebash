#!/usr/bin/env bash


set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_lib.sh"

MY_BIN="${MY_BIN:-$SCRIPT_DIR/../s21_grep/s21_grep}"
REF_BIN="${REF_BIN:-grep}"

MY_BIN="$(cd "$(dirname "$MY_BIN")" && pwd)/$(basename "$MY_BIN")"

require_bin "$MY_BIN"
command -v "$REF_BIN" >/dev/null || { echo "ref binary '$REF_BIN' not found" >&2; exit 2; }

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
cd "$TMPDIR"
setup_fixtures

echo "Testing: $MY_BIN"
echo "Against: $(command -v "$REF_BIN")"
echo

# ----- Basic pattern match -----
run_case "simple literal match"           "fox mixed.txt"
run_case "no match"                       "zzznothing mixed.txt"
run_case "match every line"               "e mixed.txt"
run_case "empty file"                     "anything empty.txt"
run_case "pattern matches nothing"        "xyzxyz mixed.txt"

# ----- -i (ignore case) -----
run_case "-i fox"                         "-i fox mixed.txt"
run_case "-i FOX"                         "-i FOX mixed.txt"
run_case "-i hello"                       "-i hello mixed.txt"
run_case "--ignore-case fox"              "--ignore-case fox mixed.txt"

# ----- -v (invert) -----
run_case "-v fox"                         "-v fox mixed.txt"
run_case "-v no-match (everything)"       "-v zzznothing mixed.txt"
run_case "-v match-all (nothing)"         "-v e mixed.txt"
run_case "--invert-match fox"             "--invert-match fox mixed.txt"

# ----- -c (count) -----
run_case "-c fox"                         "-c fox mixed.txt"
run_case "-c no-match"                    "-c zzznothing mixed.txt"
run_case "-c -v fox"                      "-cv fox mixed.txt"
run_case "--count fox"                    "--count fox mixed.txt"

# ----- -l (files with matches) -----
run_case "-l fox one file"                "-l fox mixed.txt"
run_case "-l fox no match"                "-l zzznothing mixed.txt"
run_case "-l fox multi-file"              "-l fox mixed.txt other.txt"
run_case "-l fox one matches one doesn't" "-l hello mixed.txt other.txt"

# ----- -n (line number) -----
run_case "-n fox"                         "-n fox mixed.txt"
run_case "-n -i fox"                      "-ni fox mixed.txt"
run_case "-n no-match"                    "-n zzznothing mixed.txt"

# ----- -h (no filename) -----
run_case "-h fox multi-file"              "-h fox mixed.txt other.txt"
run_case "fox multi-file (default shows names)" "fox mixed.txt other.txt"
run_case "-h -n multi-file"               "-hn fox mixed.txt other.txt"

# ----- -s (suppress errors) -----
run_case "-s missing file (stdout only)"  "-s fox does_not_exist.txt"
run_case "-s real and missing"            "-s fox mixed.txt does_not_exist.txt"

# ----- -e (regexp flag) -----
run_case "-e fox"                         "-e fox mixed.txt"
run_case "-e fox -e bar (multiple -e)"    "-e fox -e bar mixed.txt"
run_case "-e fox -e numbers"              "-e fox -e numbers mixed.txt"
run_case "-i -e FOX"                      "-ie FOX mixed.txt"

# ----- -f (patterns from file) -----
run_case "-f patterns.txt"                "-f patterns.txt mixed.txt"
run_case "-f empty_patterns.txt"          "-f empty_patterns.txt mixed.txt"
run_case "-f + -e combined"               "-f patterns.txt -e hello mixed.txt"
run_case "-f multiple patterns"           "-f patterns.txt mixed.txt other.txt"

# ----- -o (only matching) -----
run_case "-o fox"                         "-o fox mixed.txt"
run_case "-o -i fox"                      "-oi fox mixed.txt"
run_case "-o multiple matches same line"  "-o o mixed.txt"
run_case "-o -e fox -e bar"               "-o -e fox -e bar mixed.txt"
run_case "-o -n fox"                      "-on fox mixed.txt"

# ----- Multi-file -----
run_case "fox two files (prefix filenames)" "fox mixed.txt other.txt"
run_case "-c multi-file"                  "-c fox mixed.txt other.txt"
run_case "-n multi-file"                  "-n fox mixed.txt other.txt"

# ----- Regex features (BRE) -----
run_case "regex ^The"                     "^The mixed.txt"
run_case "regex dog\$"                    "'dog\$' mixed.txt"
run_case "regex . (any char)"             "'f.x' mixed.txt"
run_case "regex [0-9]"                    "'[0-9]' mixed.txt"
run_case "regex character class"          "'[Hh]ello' mixed.txt"

# ----- Flag combinations (Part 4) -----
run_case "-iv fox"                        "-iv fox mixed.txt"
run_case "-in fox"                        "-in fox mixed.txt"
run_case "-cn fox"                        "-cn fox mixed.txt"      # -c overrides -n output
run_case "-ln fox"                        "-ln fox mixed.txt"      # -l overrides -n output
run_case "-hn multi-file"                 "-hn fox mixed.txt other.txt"
run_case "-ivc fox"                       "-ivc fox mixed.txt"
run_case "-iovn fox"                      "-ion fox mixed.txt"

# ----- Edge cases -----
run_case "empty pattern via -e"           "-e '' mixed.txt"
run_case "pattern with special chars"     "'Hello,' mixed.txt"
run_case "pattern equals newline-stripped line" "'first line' simple.txt"

print_summary
