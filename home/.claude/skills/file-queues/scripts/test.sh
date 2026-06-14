#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
QUEUE="$SCRIPT_DIR/queue.sh"
TEST_DIR="/tmp/queue-test-$$"
export QUEUES_ROOT="$TEST_DIR"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

assert_eq() {
  local actual="$1" expected="$2" msg="$3"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: $msg"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    exit 1
  fi
}

echo "Testing file-queues in $TEST_DIR"

# Test 1: Add single item
$QUEUE add a/b '{"x":1}'
assert_eq "$($QUEUE count a/b)" "1" "count after add 1"

# Test 2: Add multiple items
$QUEUE add a/b '{"x":2}' '{"x":3}'
assert_eq "$($QUEUE count a/b)" "3" "count after add 2,3"

# Test 3: Peek returns first without removing
assert_eq "$($QUEUE peek a/b)" '{"x":1}' "peek first"
assert_eq "$($QUEUE count a/b)" "3" "count unchanged after peek"

# Test 4: Peek with count
assert_eq "$($QUEUE peek a/b 2)" '{"x":1}
{"x":2}' "peek 2"

# Test 5: Next removes and returns
assert_eq "$($QUEUE next a/b)" '{"x":1}' "next first"
assert_eq "$($QUEUE count a/b)" "2" "count after next 1"

# Test 6: Next with count
assert_eq "$($QUEUE next a/b 2)" '{"x":2}
{"x":3}' "next 2"
assert_eq "$($QUEUE count a/b)" "0" "count after next all"

# Test 7: Empty queue behavior
assert_eq "$($QUEUE count a/b)" "0" "empty count"
if $QUEUE next a/b 2>/dev/null; then
  echo "FAIL: next on empty should fail"
  exit 1
fi

# Test 8: Stdin add
echo '{"y":1}
{"y":2}' | $QUEUE add c/d
assert_eq "$($QUEUE count c/d)" "2" "stdin add count"

# Test 9: Dump
assert_eq "$($QUEUE dump c/d)" '{"y":1}
{"y":2}' "dump"

# Test 10: Nested paths
$QUEUE add x/y/z '{"z":1}'
assert_eq "$($QUEUE count x/y/z)" "1" "nested path"
if [ ! -f "$TEST_DIR/x/y/z.jsonl" ]; then
  echo "FAIL: nested file should exist"
  exit 1
fi

echo "All tests passed"
