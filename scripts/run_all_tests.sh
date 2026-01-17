#!/bin/bash
# scripts/run_all_tests.sh -- Master test runner

# Use the TOP variable if it exists (from Makefile), 
# otherwise calculate it relative to this script's location.
PROJECT_ROOT="${TOP:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Export the location of the binaries for the test utilities
export BIN_DIR="$PROJECT_ROOT/bin"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "========================================"
echo "   Running All Ratfor Tool Tests"
echo "   Root: $PROJECT_ROOT"
echo "========================================"

# Find all tests.sh files within the src directory
TEST_SCRIPTS=$(find "$PROJECT_ROOT/src" -name "tests.sh")

FAILED_CH_COUNT=0
TOTAL_CH_COUNT=0

for script in $TEST_SCRIPTS; do
    ((TOTAL_CH_COUNT++))
    
    # Get a clean name for display (e.g., src/ch1_getting_started/tests.sh)
    display_name="${script#$PROJECT_ROOT/}"
    echo -e "\n--> Executing: $display_name"
    
    # Run the test script
    # We use 'bash' to ensure it executes, and since tests.sh 
    # now uses BASH_SOURCE, it will find test_utils.sh correctly.
    bash "$script"
    
    if [ $? -ne 0 ]; then
        ((FAILED_CH_COUNT++))
    fi
done

echo -e "\n========================================"
if [ $FAILED_CH_COUNT -eq 0 ]; then
    echo -e "${GREEN}SUCCESS: All $TOTAL_CH_COUNT chapters passed!${NC}"
    exit 0
else
    echo -e "${RED}FAILURE: $FAILED_CH_COUNT out of $TOTAL_CH_COUNT chapters failed.${NC}"
    exit 1
fi