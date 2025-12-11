#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# User solution path
USER_DIR="."

# Check user files
USER_C_FILES=$(find "$USER_DIR" -maxdepth 1 -name "*.c")
USER_H_FILES=$(find "$USER_DIR" -maxdepth 1 -name "*.h")

if [ -z "$USER_C_FILES" ] || [ -z "$USER_H_FILES" ]; then
    echo -e "${RED}❌ User solution not found: No .c or .h files in $USER_DIR${NC}"
    exit 1
fi

# Create temporary folder
TMP_DIR=$(mktemp -d)

# Check if test.c exists to use as reference
if [ ! -f "$USER_DIR/test.c" ]; then
    echo -e "${RED}❌ Reference implementation (test.c) not found!${NC}"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Copy reference test.c and test.h
cp "$USER_DIR/test.c" "$TMP_DIR"/ref_life.c
if [ -f "$USER_DIR/test.h" ]; then
    cp "$USER_DIR/test.h" "$TMP_DIR"/ref_life.h
fi

# Copy user life.c and life.h
cp "$USER_DIR/life.c" "$TMP_DIR"/user_life.c
if [ -f "$USER_DIR/life.h" ]; then
    cp "$USER_DIR/life.h" "$TMP_DIR"/life.h
fi

cd "$TMP_DIR" || exit 1

# Compile reference (test.c)
gcc -Wall -Wextra -Werror -std=c99 -o ref_life ref_life.c 2>&1 | tee ref_compile.log >/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Reference compilation failed!${NC}"
    cat ref_compile.log
    cd - >/dev/null
    rm -rf "$TMP_DIR"
    exit 1
fi

# Compile user (life.c)
gcc -Wall -Wextra -Werror -std=c99 -o user_life user_life.c 2>&1 | tee user_compile.log >/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ User compilation failed!${NC}"
    cat user_compile.log
    cd - >/dev/null
    rm -rf "$TMP_DIR"
    exit 1
fi

# Helper function to run tests silently
run_test() {
    local test_name="$1"
    local input="$2"
    local rows="$3"
    local cols="$4"
    local iter="$5"
    local ref_out="ref_${test_name}.txt"
    local user_out="user_${test_name}.txt"

    echo "$input" | ./ref_life "$rows" "$cols" "$iter" > "$ref_out" 2>&1
    echo "$input" | ./user_life "$rows" "$cols" "$iter" > "$user_out" 2>&1

    if diff -q "$ref_out" "$user_out" >/dev/null; then
        return 0
    else
        echo -e "${RED}❌ $test_name failed! Output differs from reference:${NC}"
        echo -e "${BLUE}Reference output (test.c):${NC}"
        cat "$ref_out"
        echo -e "${BLUE}User output (life.c):${NC}"
        cat "$user_out"
        echo -e "${YELLOW}Diff (< reference, > user):${NC}"
        diff "$ref_out" "$user_out"
        return 1
    fi
}

# Run all tests
run_test "Test1_Basic" "sdxddssaaww" 5 5 0
test1_match=$?

run_test "Test2_Complex" "sdxssdswdxddddsxaadwxwdxwaa" 10 6 0
test2_match=$?

run_test "Test3_Vertical" "dxss" 3 3 0
test3_match=$?

run_test "Test4_Evolution1" "dxss" 3 3 1
test4_match=$?

run_test "Test5_Evolution2" "dxss" 3 3 2
test5_match=$?

run_test "Test6_Empty" "" 3 3 0
test6_match=$?

# Valgrind check (if available)
has_leaks=""
has_errors=""
valgrind_skipped=false

if command -v valgrind >/dev/null 2>&1; then
    valgrind_output=$(echo 'sdxddssaaww' | valgrind \
        --leak-check=full --show-leak-kinds=all --track-origins=yes -s \
        ./user_life 5 5 0 2>&1)
    has_leaks=$(echo "$valgrind_output" | grep -E "definitely lost: [^0]" || echo "")
    has_errors=$(echo "$valgrind_output" | grep -E "ERROR SUMMARY: [^0]" || echo "")
else
    valgrind_skipped=true
fi

# Determine overall result
all_passed=true
for t in $test1_match $test2_match $test3_match $test4_match $test5_match $test6_match; do
    if [ $t -ne 0 ]; then
        all_passed=false
    fi
done
if [ -n "$has_leaks" ] || [ -n "$has_errors" ]; then
    all_passed=false
fi

# Print results
echo "======================================="
if [ "$all_passed" = true ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    echo ""
    echo -e "${GREEN}✓${NC} Test1_Basic"
    echo -e "${GREEN}✓${NC} Test2_Complex"
    echo -e "${GREEN}✓${NC} Test3_Vertical"
    echo -e "${GREEN}✓${NC} Test4_Evolution1"
    echo -e "${GREEN}✓${NC} Test5_Evolution2"
    echo -e "${GREEN}✓${NC} Test6_Empty"

    if [ "$valgrind_skipped" = true ]; then
        echo -e "${YELLOW}⚠${NC} Valgrind check skipped (not installed)"
        echo -e "  Install with: ${BLUE}brew install valgrind${NC}"
    else
        echo -e "${GREEN}✓${NC} No memory leaks detected"
    fi
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo ""

    [ $test1_match -eq 0 ] && echo -e "${GREEN}✓${NC} Test1_Basic" || echo -e "${RED}✗${NC} Test1_Basic"
    [ $test2_match -eq 0 ] && echo -e "${GREEN}✓${NC} Test2_Complex" || echo -e "${RED}✗${NC} Test2_Complex"
    [ $test3_match -eq 0 ] && echo -e "${GREEN}✓${NC} Test3_Vertical" || echo -e "${RED}✗${NC} Test3_Vertical"
    [ $test4_match -eq 0 ] && echo -e "${GREEN}✓${NC} Test4_Evolution1" || echo -e "${RED}✗${NC} Test4_Evolution1"
    [ $test5_match -eq 0 ] && echo -e "${GREEN}✓${NC} Test5_Evolution2" || echo -e "${RED}✗${NC} Test5_Evolution2"
    [ $test6_match -eq 0 ] && echo -e "${GREEN}✓${NC} Test6_Empty" || echo -e "${RED}✗${NC} Test6_Empty"

    if [ "$valgrind_skipped" = true ]; then
        echo -e "${YELLOW}⚠${NC} Valgrind check skipped (not installed)"
    else
        [ -n "$has_leaks" ] && echo -e "${RED}✗${NC} Memory leaks detected" || echo -e "${GREEN}✓${NC} No memory leaks"
        [ -n "$has_errors" ] && echo -e "${RED}✗${NC} Valgrind errors detected"
    fi
fi
echo "======================================="

# Cleanup
cd - >/dev/null
rm -rf "$TMP_DIR"