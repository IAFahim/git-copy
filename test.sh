#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR=$(mktemp -d)
SCRIPT_PATH="$SCRIPT_DIR/install.sh"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "\n${CYAN}=== GIT-COPY TEST SUITE (Unix) ===${NC}"
echo -e "${GRAY}Test directory: $TEST_DIR${NC}\n"

cd "$TEST_DIR"

cleanup() {
    cd /
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

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
    echo -e " ${GREEN}PASS${NC}"
else
    echo -e " ${RED}FAIL${NC}"
    echo "Output: $output"
    exit 1
fi

# Test 2: Filter by extension
echo -n "[TEST 2] Filter by extension (js)..."
output=$(capture_output js)
if echo "$output" | grep -q "files"; then
    echo -e " ${GREEN}PASS${NC}"
else
    echo -e " ${RED}FAIL${NC}"
    exit 1
fi

# Test 3: Filter by preset
echo -n "[TEST 3] Filter by preset (web)..."
output=$(capture_output web)
if echo "$output" | grep -q "files"; then
    echo -e " ${GREEN}PASS${NC}"
else
    echo -e " ${RED}FAIL${NC}"
    exit 1
fi

# Test 4: Exclude folder using -path syntax
echo -n "[TEST 4] Exclude folder (-temp)..."
"$EMBEDDED_SCRIPT" -temp 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "temp.txt" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${NC}"
    else
        echo -e " ${RED}FAIL${NC}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${NC}"
    exit 1
fi

# Test 5: Exclude nested folder
echo -n "[TEST 5] Exclude nested folder (-src/components)..."
"$EMBEDDED_SCRIPT" -src/components 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "Button.jsx" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${NC}"
    else
        echo -e " ${RED}FAIL${NC}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${NC}"
    exit 1
fi

# Test 6: Multiple excludes
echo -n "[TEST 6] Multiple excludes (-temp -src)..."
"$EMBEDDED_SCRIPT" -temp -src 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "temp.txt\|Main.java\|Button.jsx" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${NC}"
    else
        echo -e " ${RED}FAIL${NC}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${NC}"
    exit 1
fi

# Test 7: Filter and exclude combined
echo -n "[TEST 7] Filter (web) + Exclude (-src)..."
"$EMBEDDED_SCRIPT" web -src 2>&1 | grep -v "Processing..." >/dev/null
# Check the clipboard mock file
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if grep -q "test.js" "$HOME/mock_clipboard.txt" 2>/dev/null && ! grep -q "Button.jsx" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${NC}"
    else
        echo -e " ${RED}FAIL${NC}"
        cat "$HOME/mock_clipboard.txt"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No clipboard output${NC}"
    exit 1
fi

# Test 8: --exclude flag syntax
echo -n "[TEST 8] Using --exclude flag..."
"$EMBEDDED_SCRIPT" --exclude temp 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "temp.txt" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${NC}"
    else
        echo -e " ${RED}FAIL${NC}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${NC}"
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
        echo -e " ${GREEN}PASS${NC}"
    else
        echo -e " ${RED}FAIL${NC}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${NC}"
    exit 1
fi

rm -f "$EMBEDDED_SCRIPT"

echo -e "\n${GREEN}=== ALL TESTS PASSED ===${NC}\n"
