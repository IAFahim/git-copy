#!/bin/bash

# ==============================================================================
# 🌌 ENDGAME INSTALLER: git-copy (v6.0)
# Stability: 100% | Aesthetics: God Tier | Logic: Whitelist
# ==============================================================================

TOOL_NAME="git-copy"
INSTALL_DIR="/usr/local/bin"
TARGET_PATH="$INSTALL_DIR/$TOOL_NAME"

# Installer Colors
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${PURPLE}________  ________  ________   __${NC}"
echo -e "${PURPLE}|___  ___||   __   ||   __   | |  |${NC}"
echo -e "${PURPLE}   |  |   |  |  |  ||  |  |  | |  |${NC}"
echo -e "${PURPLE}   |  |   |  |__|  ||  |__|  | |  |__${NC}"
echo -e "${PURPLE}   |__|   |________||________| |_____|${NC}"
echo -e "${CYAN}   >> SYSTEM OPTIMIZATION: MAXIMUM <<${NC}"
echo ""

# 1. Permission Check
SUDO=""
if [ ! -w "$INSTALL_DIR" ]; then
    if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; else
        echo -e "${RED}💀 Fatal: Need root access to write to $INSTALL_DIR${NC}"; exit 1
    fi
fi

# 2. Write the Script
$SUDO tee "$TARGET_PATH" > /dev/null << 'EOF'
#!/usr/bin/env bash

# 🛡️ STRICT MODE
set -o nounset
set -o pipefail
# set -o errexit # Disabled so read errors don't kill the whole process

# ------------------------------------------------------------------------------
# 🎨 VISUALS & CONFIG
# ------------------------------------------------------------------------------
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 🧠 THE BRAIN (Whitelist Logic)
# Trust these extensions implicitly. Do not scan them for binary data.
SAFE_EXTENSIONS="cs|csproj|sln|user|vs|json|xml|html|css|scss|less|js|jsx|ts|tsx|vue|svelte|py|rb|go|rs|java|kt|c|h|cpp|hpp|sh|bash|zsh|yaml|yml|toml|md|txt|sql|graphql|dockerfile|makefile|gradle|properties|editorconfig|gitignore|env|conf|ini|svg|http"

# 🗑️ THE FILTER (Noise)
IGNORE_FILES="package-lock.json|yarn.lock|Cargo.lock|Gemfile.lock|.DS_Store|Thumbs.db"
SECURITY_FILES="id_rsa|id_dsa|.pem|.key|.p12|secrets"

# Settings
MAX_SIZE_KB=1000
TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'git-copy')
CONTEXT_FILE="${TEMP_DIR}/context.md"

trap "rm -rf $TEMP_DIR" EXIT

# ------------------------------------------------------------------------------
# 🛠️ CORE FUNCTIONS
# ------------------------------------------------------------------------------

copy_output() {
    if [[ "$OSTYPE" == "darwin"* ]]; then pbcopy
    elif [ -n "${WSL_DISTRO_NAME:-}" ]; then clip.exe
    elif command -v wl-copy >/dev/null 2>&1; then wl-copy
    elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard
    else cat; fi
}

# 🌳 THE CLEAN TREE
# Uses clean indentation (2 spaces) instead of pipes for max token efficiency.
generate_tree() {
    sort | awk -F'/' '
    BEGIN { print "." }
    {
        indent = ""
        for (i=1; i<NF; i++) {
            if ($i != p[i]) {
                # Print directory name
                print indent $i "/"
                for (k=i; k<=NF; k++) p[k] = "" 
            }
            indent = indent "  "
        }
        # Print file name
        print indent $NF
        split($0, p, "/")
    }'
}

get_lang() {
    local ext="${1##*.}"
    case "$ext" in
        cs|csproj) echo "csharp" ;;
        js|jsx|ts|tsx) echo "typescript" ;;
        py) echo "python" ;;
        java) echo "java" ;;
        go) echo "go" ;;
        rs) echo "rust" ;;
        html) echo "html" ;;
        css) echo "css" ;;
        json) echo "json" ;;
        md) echo "markdown" ;;
        sql) echo "sql" ;;
        xml|csproj|sln) echo "xml" ;;
        yaml|yml) echo "yaml" ;;
        sh) echo "bash" ;;
        *) echo "$ext" ;;
    esac
}

# ------------------------------------------------------------------------------
# 🚀 MAIN EXECUTION
# ------------------------------------------------------------------------------

# 1. Discover Context
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ROOT=$(git rev-parse --show-toplevel)
    git ls-files -z --exclude-standard -c -o . > "${TEMP_DIR}/raw"
else
    ROOT=$(pwd)
    find . -type f -not -path '*/.*' -print0 > "${TEMP_DIR}/raw"
fi

# 2. Sort List
LIST_FILE="${TEMP_DIR}/list"
xargs -0 -n 1 < "${TEMP_DIR}/raw" | sort > "$LIST_FILE"

# 3. Generate Header
{
    echo "# Project Context"
    echo "- **Root:** \`$ROOT\`"
    echo "- **Date:** $(date)"
    echo ""
    echo "## Structure"
    echo "\`\`\`text"
    cat "$LIST_FILE" | generate_tree
    echo "\`\`\`"
    echo ""
} > "$CONTEXT_FILE"

# 4. Process Files
COUNT=0
TOTAL_LINES=0
TOTAL_BYTES=0
SKIP_BIN=0
SKIP_SIZE=0

while IFS= read -r file; do
    [ -z "$file" ] && continue
    [[ "$(basename "$file")" == "git-copy" ]] && continue
    [ ! -f "$file" ] && continue

    # Visual Spinner
    ((COUNT++))
    printf "\r${CYAN}⚡ Scanning file $COUNT...${NC}" >&2

    # A. Security Check
    if [[ "$file" =~ $SECURITY_FILES ]]; then
        echo "## File: \`$file\`" >> "$CONTEXT_FILE"
        echo "> 🔒 **CENSORED (Security)**" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        continue
    fi
    
    # B. Noise Check
    if [[ "$file" =~ $IGNORE_FILES ]]; then continue; fi

    # C. Whitelist Logic
    DO_COPY=false
    EXT="${file##*.}"
    LOWER_EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
    
    # C1. Whitelist Check (Fast Track)
    if [[ "$SAFE_EXTENSIONS" =~ (^|\|)$LOWER_EXT($|\|) ]]; then
        DO_COPY=true
    else
        # C2. Native File Check (Slow Track)
        if file -b --mime "$file" 2>/dev/null | grep -q "text"; then
            DO_COPY=true
        else
             # Try Mac specific flag
            if file -bI "$file" 2>/dev/null | grep -q "text"; then DO_COPY=true; fi
        fi
    fi

    if [ "$DO_COPY" = true ]; then
        # Size Check
        SIZE=$(wc -c < "$file")
        if [ "$SIZE" -gt $((MAX_SIZE_KB * 1024)) ]; then
            echo "## File: \`$file\`" >> "$CONTEXT_FILE"
            echo "> ⚠️ **SKIPPED (Too Large: $((SIZE/1024))KB)**" >> "$CONTEXT_FILE"
            echo "" >> "$CONTEXT_FILE"
            ((SKIP_SIZE++))
        else
            # COPY
            LINES=$(wc -l < "$file")
            ((TOTAL_LINES+=LINES))
            ((TOTAL_BYTES+=SIZE))
            
            LANG=$(get_lang "$file")
            echo "## File: \`$file\`" >> "$CONTEXT_FILE"
            echo "\`\`\`$LANG" >> "$CONTEXT_FILE"
            cat "$file" >> "$CONTEXT_FILE"
            echo "" >> "$CONTEXT_FILE"
            echo "\`\`\`" >> "$CONTEXT_FILE"
            echo "" >> "$CONTEXT_FILE"
        fi
    else
        echo "## File: \`$file\`" >> "$CONTEXT_FILE"
        echo "> 🤖 **SKIPPED (Binary)**" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        ((SKIP_BIN++))
    fi

done < "$LIST_FILE"

printf "\r\033[K" >&2

# 5. Final Output & Stats
cat "$CONTEXT_FILE" | copy_output

# Calc Tokens (Approx 1 token = 4 chars)
TOKENS=$((TOTAL_BYTES / 4))
SIZE_KB=$((TOTAL_BYTES / 1024))

echo -e "${GREEN}${BOLD}✔ Copied to Clipboard!${NC}"
echo -e "${DIM}────────────────────────────────────────${NC}"
echo -e "📄 Files:     ${BOLD}${COUNT}${NC}"
echo -e "📝 Lines:     ${BOLD}${TOTAL_LINES}${NC}"
echo -e "💾 Size:      ${BOLD}${SIZE_KB} KB${NC}"
echo -e "🧠 Tokens:    ${BOLD}~${TOKENS}${NC} (GPT-4 Est.)"
echo -e "${DIM}────────────────────────────────────────${NC}"

if [ "$SKIP_BIN" -gt 0 ] || [ "$SKIP_SIZE" -gt 0 ]; then
    echo -e "${YELLOW}⚠ Skipped: ${SKIP_BIN} binary, ${SKIP_SIZE} large files.${NC}"
fi

EOF

# 3. Finalize
$SUDO chmod +x "$TARGET_PATH"
echo -e "${GREEN}✅ Installation Complete.${NC}"
echo -e "Run ${BOLD}git-copy${NC} in your project."
