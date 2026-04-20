#!/usr/bin/env bash


set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_lib.sh"


MY_BIN="${MY_BIN:-$SCRIPT_DIR/../s21_cat/s21_cat}"

REF_BIN="${REF_BIN:-cat}"


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

# ----- No flags -----
run_case "cat simple.txt"                   "simple.txt"
run_case "cat empty.txt"                    "empty.txt"
run_case "cat no_newline.txt"               "no_newline.txt"
run_case "cat multiple files"               "simple.txt other.txt"
run_case "cat missing file"                 "does_not_exist.txt"
run_case "cat mix of real and missing"      "simple.txt missing.txt other.txt"

# ----- -n (number all lines) -----
run_case "cat -n simple"                    "-n simple.txt"
run_case "cat -n empty"                     "-n empty.txt"
run_case "cat -n blanks"                    "-n blanks.txt"
run_case "cat -n no-newline"                "-n no_newline.txt"
run_case "cat --number simple"              "--number simple.txt"

# ----- -b (number nonblank) -----
run_case "cat -b blanks"                    "-b blanks.txt"
run_case "cat -b simple"                    "-b simple.txt"
run_case "cat -b empty"                     "-b empty.txt"
run_case "cat --number-nonblank blanks"     "--number-nonblank blanks.txt"

# ----- -s (squeeze blank lines) -----
run_case "cat -s blanks"                    "-s blanks.txt"
run_case "cat -s simple (no blanks)"        "-s simple.txt"
run_case "cat --squeeze-blank blanks"       "--squeeze-blank blanks.txt"

# ----- -E (show ends) -----
run_case "cat -E simple"                    "-E simple.txt"
run_case "cat -E blanks"                    "-E blanks.txt"
run_case "cat -E empty"                     "-E empty.txt"
run_case "cat --show-ends simple"           "--show-ends simple.txt"

# ----- -T (show tabs) -----
run_case "cat -T tabs"                      "-T tabs.txt"
run_case "cat -T simple (no tabs)"          "-T simple.txt"
run_case "cat --show-tabs tabs"             "--show-tabs tabs.txt"

# ----- Flag combinations (Part 4 bonus) -----
run_case "cat -ns blanks"                   "-ns blanks.txt"    
run_case "cat -nE simple"                   "-nE simple.txt"
run_case "cat -bs blanks"                   "-bs blanks.txt"
run_case "cat -bE blanks"                   "-bE blanks.txt"
run_case "cat -ET tabs"                     "-ET tabs.txt"
run_case "cat -nET simple"                  "-nET simple.txt"
run_case "cat -nETs blanks"                 "-nETs blanks.txt"
run_case "cat -bETs blanks"                 "-bETs blanks.txt"

# ----- -v, -e, -t (nonprinting) -----

run_case "cat -v ctrl"                      "-v ctrl.txt"
run_case "cat -e simple (implies -v -E)"    "-e simple.txt"
run_case "cat -t tabs (implies -v -T)"      "-t tabs.txt"
run_case "cat -vE ctrl"                     "-vE ctrl.txt"

# ----- Multi-file with flags -----
run_case "cat -n two files"                 "-n simple.txt other.txt"
run_case "cat -s two files (-s across boundary)" "-s blanks.txt blanks.txt"
run_case "cat -b two files"                 "-b blanks.txt simple.txt"

# ----- -b overrides -n -----
run_case "cat -bn blanks (-b wins)"         "-bn blanks.txt"
run_case "cat -nb blanks (-b wins)"         "-nb blanks.txt"

print_summary
