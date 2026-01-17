#!/bin/bash
# Get the absolute path to the directory containing this script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Source the shared runner using the absolute path
source "$SCRIPT_DIR/../../scripts/test_utils.sh"

# Move into the script's directory so it finds the compiled binaries (./copy, etc.)
cd "$SCRIPT_DIR"

echo "--- Testing Chapter 1 Tools ---"

# 1. COPY
run_test "copy (basic)" "hello\n" "hello\n" "copy"

# 2. CHARCOUNT
run_test "charcount (hello)" "hello\n" "6" "charcount"

# 3. LINECOUNT
run_test "linecount (2 lines)" "one\ntwo\n" "2" "linecount"

# 4. WORDCOUNT
run_test "wordcount (basic)" "one two three\n" "3" "wordcount"
run_test "wordcount (whitespace)" "  one   two  \n" "2" "wordcount"

# 5. DETAB
run_test "detab (standard)" "col1\tcol2\n" "col1    col2\n" "detab"

report_results

