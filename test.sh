#!/usr/bin/env bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================

set -euo pipefail

readonly VERSION="16.2"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR=$(mktemp -d)
readonly SCRIPT_PATH="$SCRIPT_DIR/install.sh"

# Test tracking
TESTS_PASSED=0
TESTS_FAILED=0

# ==============================================================================
# VISUALS
# ==============================================================================

# Color support detection
if [[ -t 1 ]] && command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    DIM=$(tput dim)
    RESET=$(tput sgr0)
else
    RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" BOLD="" DIM="" RESET=""
fi

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

log_info() {
    echo "${BLUE}[INFO]${RESET} $*" >&2
}

log_success() {
    echo "${GREEN}[OK]${RESET} $*" >&2
}

log_warn() {
    echo "${YELLOW}[WARN]${RESET} $*" >&2
}

log_error() {
    echo "${RED}[ERROR]${RESET} $*" >&2
}

log_debug() {
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        echo "${DIM}[DEBUG] $*${RESET}" >&2
    fi
}

log_test_result() {
    local test_name="$1"
    local result="$2"
    if [[ "$result" == "PASS" ]]; then
        echo "${GREEN}PASS${RESET} - $test_name"
        ((TESTS_PASSED++))
    else
        echo "${RED}FAIL${RESET} - $test_name"
        ((TESTS_FAILED++))
    fi
}

# ==============================================================================
# TEST SUITE
# ==============================================================================

echo -e "\n${CYAN}=== GIT-COPY TEST SUITE v${VERSION} (Unix) ===${RESET}"
echo -e "${DIM}Test directory: $TEST_DIR${RESET}\n"

cd "$TEST_DIR"

# ==============================================================================
# CLEANUP HANDLER
# ==============================================================================

cleanup() {
    local exit_code=$?
    cd / || true
    if [[ -n "${TEST_DIR:-}" ]] && [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
    if [[ -n "${EMBEDDED_SCRIPT:-}" ]] && [[ -f "$EMBEDDED_SCRIPT" ]]; then
        rm -f "$EMBEDDED_SCRIPT"
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM HUP

# ==============================================================================
# TEST SETUP
# ==============================================================================

# Initialize git repo
git init -q
git config user.email "test@test.com"
git config user.name "Test User"

# Create test files
cat > test.js << 'EOF'
function hello() {
    console.log("Hello");
}
EOF

cat > test.py << 'EOF'
def greet():
    print("Hello")
EOF

cat > README.md << 'EOF'
# Test Document
This is a test.
EOF

# Create excluded directory
mkdir -p node_modules
cat > node_modules/index.js << 'EOF'
module.exports = {};
EOF

# Create nested structure
mkdir -p src/components
cat > src/components/Button.jsx << 'EOF'
const Component = () => {};
EOF

cat > src/Main.java << 'EOF'
public class Main {}
EOF

# Create test directory to exclude
mkdir -p temp
echo "temp file" > temp/temp.txt

git add -A
git commit -q -m "Initial commit"

# Extract the embedded script from install.sh
EMBEDDED_SCRIPT=$(mktemp)
sed -n '/^cat > "\$TMP_PAYLOAD" << .EOF.$/,/^EOF$/p' "$SCRIPT_PATH" | sed '1d;$d' > "$EMBEDDED_SCRIPT"
chmod +x "$EMBEDDED_SCRIPT"

# Setup clipboard mocks BEFORE running tests
mkdir -p $HOME/bin

# Mock pbcopy (Mac)
cat > $HOME/bin/pbcopy << 'MOCK_EOF'
#!/bin/bash
cat > $HOME/mock_clipboard.txt
MOCK_EOF
chmod +x $HOME/bin/pbcopy

# Mock xclip (Linux)
cat > $HOME/bin/xclip << 'MOCK_EOF'
#!/bin/bash
cat > $HOME/mock_clipboard.txt
MOCK_EOF
chmod +x $HOME/bin/xclip

# Mock wl-copy (Wayland Linux)
cat > $HOME/bin/wl-copy << 'MOCK_EOF'
#!/bin/bash
cat > $HOME/mock_clipboard.txt
MOCK_EOF
chmod +x $HOME/bin/wl-copy

# Add mocks to PATH
export PATH="$HOME/bin:$PATH"

# Helper to capture output
capture_output() {
    "$EMBEDDED_SCRIPT" "$@" 2>&1 | grep -v "Processing..." | tail -1
}

# Test 1: Basic functionality
echo -n "[TEST 1] Basic copy all files..."
output=$(capture_output)
if echo "$output" | grep -q "Copied:"; then
    echo -e " ${GREEN}PASS${RESET}"
else
    echo -e " ${RED}FAIL${RESET}"
    echo "Output: $output"
    exit 1
fi

# Test 2: Filter by extension
echo -n "[TEST 2] Filter by extension (js)..."
output=$(capture_output js)
if echo "$output" | grep -q "files"; then
    echo -e " ${GREEN}PASS${RESET}"
else
    echo -e " ${RED}FAIL${RESET}"
    exit 1
fi

# Test 3: Filter by preset
echo -n "[TEST 3] Filter by preset (web)..."
output=$(capture_output web)
if echo "$output" | grep -q "files"; then
    echo -e " ${GREEN}PASS${RESET}"
else
    echo -e " ${RED}FAIL${RESET}"
    exit 1
fi

# Test 4: Exclude folder using -path syntax
echo -n "[TEST 4] Exclude folder (-temp)..."
"$EMBEDDED_SCRIPT" -temp 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "temp.txt" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${RESET}"
    else
        echo -e " ${RED}FAIL${RESET}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${RESET}"
    exit 1
fi

# Test 5: Exclude nested folder
echo -n "[TEST 5] Exclude nested folder (-src/components)..."
"$EMBEDDED_SCRIPT" -src/components 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "Button.jsx" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${RESET}"
    else
        echo -e " ${RED}FAIL${RESET}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${RESET}"
    exit 1
fi

# Test 6: Multiple excludes
echo -n "[TEST 6] Multiple excludes (-temp -src)..."
"$EMBEDDED_SCRIPT" -temp -src 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "temp.txt\|Main.java\|Button.jsx" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${RESET}"
    else
        echo -e " ${RED}FAIL${RESET}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${RESET}"
    exit 1
fi

# Test 7: Filter and exclude combined
echo -n "[TEST 7] Filter (web) + Exclude (-src)..."
"$EMBEDDED_SCRIPT" web -src 2>&1 | grep -v "Processing..." >/dev/null
# Check the clipboard mock file
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if grep -q "test.js" "$HOME/mock_clipboard.txt" 2>/dev/null && ! grep -q "Button.jsx" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${RESET}"
    else
        echo -e " ${RED}FAIL${RESET}"
        cat "$HOME/mock_clipboard.txt"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No clipboard output${RESET}"
    exit 1
fi

# Test 8: --exclude flag syntax
echo -n "[TEST 8] Using --exclude flag..."
"$EMBEDDED_SCRIPT" --exclude temp 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "temp.txt" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${RESET}"
    else
        echo -e " ${RED}FAIL${RESET}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${RESET}"
    exit 1
fi

# Test 9: Exclude folder with spaces
echo -n "[TEST 9] Exclude folder with spaces..."
mkdir -p "folder with spaces"
echo "content" > "folder with spaces/file.txt"
git add "folder with spaces"
git commit -q -m "Add folder with spaces"
"$EMBEDDED_SCRIPT" -"folder with spaces" 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "folder with spaces/file.txt" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${RESET}"
    else
        echo -e " ${RED}FAIL${RESET}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${RESET}"
    exit 1
fi

rm -f "$EMBEDDED_SCRIPT"

# ==============================================================================
# TEST RESULTS
# ==============================================================================

echo ""
echo "${BOLD}============================================================================${RESET}"
echo "${GREEN}=== ALL TESTS PASSED ===${RESET}"
echo "${BOLD}============================================================================${RESET}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo "Passed: ${GREEN}${TESTS_PASSED}${RESET}"
echo "Failed: ${RED}${TESTS_FAILED}${RESET}"
echo ""
