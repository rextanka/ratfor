#!/bin/bash
# scripts/test_utils.sh -- Shared testing logic

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
FAILS=0

run_test() {
    test_name="$1"
    input_str="$2"
    expected_raw="$3" 
    tool_name="$4"

    # Use the exported BIN_DIR if available, otherwise assume current dir
    if [ -n "$BIN_DIR" ] && [ -f "$BIN_DIR/$tool_name" ]; then
        exe="$BIN_DIR/$tool_name"
    else
        exe="./$tool_name"
    fi

    if [ ! -f "$exe" ]; then
        echo -e "${RED}[FAIL]${NC} $test_name: Executable $tool_name not found."
        ((FAILS++))
        return
    fi

    # Capture ACTUAL output (preserve newlines)
    actual=$(printf "%b" "$input_str" | "$exe" ; printf x)
    actual="${actual%x}"

    # Capture EXPECTED output (preserve newlines)
    expected_expanded=$(printf "%b" "$expected_raw" ; printf x)
    expected_expanded="${expected_expanded%x}"

    # Compare
    # For counting tools, we ignore whitespace differences. For others (copy/detab), strict match.
    if [[ "$4" == "copy" || "$4" == "detab" || "$4" == "entab" ]]; then
         if [ "$actual" == "$expected_expanded" ]; then
            echo -e "${GREEN}[PASS]${NC} $test_name"
        else
            echo -e "${RED}[FAIL]${NC} $test_name"
            echo "       Input:    $(printf "%q" "$input_str")"
            echo "       Expected: $(printf "%q" "$expected_expanded")"
            echo "       Actual:   $(printf "%q" "$actual")"
            ((FAILS++))
        fi
    else
        clean_actual=$(echo "$actual" | tr -d '[:space:]')
        clean_expected=$(echo "$expected_expanded" | tr -d '[:space:]')

        if [ "$clean_actual" == "$clean_expected" ]; then
            echo -e "${GREEN}[PASS]${NC} $test_name"
        else
            echo -e "${RED}[FAIL]${NC} $test_name"
            echo "       Input:    '$input_str'"
            echo "       Expected: '$expected_raw'"
            echo "       Actual:   '$actual'"
            ((FAILS++))
        fi
    fi
}

report_results() {
    echo "------------------------------"
    if [ $FAILS -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}$FAILS test(s) failed.${NC}"
        exit 1
    fi
}