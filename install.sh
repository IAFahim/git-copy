#!/bin/bash

# ==============================================================================
# 🧘 GIT-COPY: ZEN EDITION (v7.0)
# "Perfection is achieved not when there is nothing more to add, 
#  but when there is nothing left to take away."
# ==============================================================================

TOOL_NAME="git-copy"
INSTALL_DIR="/usr/local/bin"
TARGET_PATH="$INSTALL_DIR/$TOOL_NAME"

# Installer Visuals
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}>> INSTALLING GIT-COPY (ZEN EDITION) <<${NC}"

# Elevation
SUDO=""
[ ! -w "$INSTALL_DIR" ] && command -v sudo >/dev/null && SUDO="sudo"

# The Payload
$SUDO tee "$TARGET_PATH" > /dev/null << 'EOF'
#!/usr/bin/env bash

# Strict Mode
set -o nounset
set -o pipefail

# ------------------------------------------------------------------------------
# ⚙️ CONFIG
# ------------------------------------------------------------------------------
# Colors
GREEN='\033[0;32m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
CYAN='\033[0;36m'

# Logic
SAFE_EXTENSIONS="cs|csproj|sln|user|vs|json|xml|html|css|scss|less|js|jsx|ts|tsx|vue|svelte|py|rb|go|rs|java|kt|c|h|cpp|hpp|sh|bash|zsh|yaml|yml|toml|md|txt|sql|graphql|dockerfile|makefile|gradle|properties|editorconfig|gitignore|env|conf|ini|svg|http"
IGNORE_FILES="package-lock.json|yarn.lock|Cargo.lock|Gemfile.lock|.DS_Store|Thumbs.db"
SECURITY_FILES="id_rsa|id_dsa|.pem|.key|.p12|secrets"
MAX_SIZE_KB=1000

# Temp
TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'git-copy')
CONTEXT_FILE="${TEMP_DIR}/context.md"
trap "rm -rf $TEMP_DIR" EXIT

# ------------------------------------------------------------------------------
# 🛠️ UTILS
# ------------------------------------------------------------------------------

copy_output() {
    if [[ "$OSTYPE" == "darwin"* ]]; then pbcopy
    elif [ -n "${WSL_DISTRO_NAME:-}" ]; then clip.exe
    elif command -v wl-copy >/dev/null 2>&1; then wl-copy
    elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard
    else cat; fi
}

generate_clean_tree() {
    sort | awk -F'/' '
    BEGIN { print "." }
    {
        indent = ""
        for (i=1; i<NF; i++) {
            if ($i != p[i]) {
                print indent $i "/"
                for (k=i; k<=NF; k++) p[k] = "" 
            }
            indent = indent "  "
        }
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
# 🚀 EXECUTION
# ------------------------------------------------------------------------------

# 1. Discover
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ROOT=$(git rev-parse --show-toplevel)
    git ls-files -z --exclude-standard -c -o . > "${TEMP_DIR}/raw"
else
    ROOT=$(pwd)
    find . -type f -not -path '*/.*' -print0 > "${TEMP_DIR}/raw"
fi

# 2. Sort & Filter
LIST_FILE="${TEMP_DIR}/list"
xargs -0 -n 1 < "${TEMP_DIR}/raw" | sort > "$LIST_FILE"

# 3. Header
{
    echo "# Context: $(basename "$ROOT")"
    echo "## Structure"
    echo "\`\`\`text"
    cat "$LIST_FILE" | generate_clean_tree
    echo "\`\`\`"
    echo ""
} > "$CONTEXT_FILE"

# 4. Process
COUNT=0
TOTAL_BYTES=0

while IFS= read -r file; do
    [ -z "$file" ] && continue
    [[ "$(basename "$file")" == "git-copy" ]] && continue
    [ ! -f "$file" ] && continue

    # Visual (Overwrites itself line by line)
    printf "\r${DIM}Scanning... $file${NC}\033[K" >&2

    # Logic
    if [[ "$file" =~ $SECURITY_FILES ]]; then continue; fi
    if [[ "$file" =~ $IGNORE_FILES ]]; then continue; fi

    DO_COPY=false
    EXT="${file##*.}"
    LOWER_EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
    
    # Whitelist vs Native Check
    if [[ "$SAFE_EXTENSIONS" =~ (^|\|)$LOWER_EXT($|\|) ]]; then
        DO_COPY=true
    elif file -b --mime "$file" 2>/dev/null | grep -q "text"; then
        DO_COPY=true
    elif file -bI "$file" 2>/dev/null | grep -q "text"; then 
        DO_COPY=true
    fi

    if [ "$DO_COPY" = true ]; then
        SIZE=$(wc -c < "$file")
        if [ "$SIZE" -lt $((MAX_SIZE_KB * 1024)) ]; then
            ((COUNT++))
            ((TOTAL_BYTES+=SIZE))
            LANG=$(get_lang "$file")
            
            echo "## File: \`$file\`" >> "$CONTEXT_FILE"
            echo "\`\`\`$LANG" >> "$CONTEXT_FILE"
            cat "$file" >> "$CONTEXT_FILE"
            echo "" >> "$CONTEXT_FILE"
            echo "\`\`\`" >> "$CONTEXT_FILE"
            echo "" >> "$CONTEXT_FILE"
        fi
    fi
done < "$LIST_FILE"

# 5. Output
cat "$CONTEXT_FILE" | copy_output
printf "\r\033[K" >&2 # Clear scanning line

TOKENS=$((TOTAL_BYTES / 4))
if [ "$TOKENS" -gt 1000 ]; then TOKEN_STR="$((TOKENS/1000))k"; else TOKEN_STR="$TOKENS"; fi

# THE ONE LINER
echo -e "${GREEN}✔ Copied ${BOLD}${COUNT}${NC}${GREEN} files (${BOLD}~${TOKEN_STR} tokens${NC}${GREEN}) to clipboard.${NC}"

EOF

$SUDO chmod +x "$TARGET_PATH"
echo -e "${GREEN}✔ Installed.${NC}"
