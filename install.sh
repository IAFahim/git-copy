#!/bin/bash

# ==============================================================================
# 💎 OMNI-COPY: The Immutable Edition (v5.0)
# "It doesn't guess. It knows."
# ==============================================================================

TOOL_NAME="git-copy"
INSTALL_DIR="/usr/local/bin"
TARGET_PATH="$INSTALL_DIR/$TOOL_NAME"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}>> INSTALLING OMNI-COPY (WHITELIST ENGINE) <<${NC}"

# Elevation
SUDO=""
[ ! -w "$INSTALL_DIR" ] && command -v sudo >/dev/null && SUDO="sudo"

# Write Script
$SUDO tee "$TARGET_PATH" > /dev/null << 'EOF'
#!/usr/bin/env bash

# Strict Mode
set -o nounset
set -o pipefail

# ------------------------------------------------------------------------------
# 🛡️ CONFIGURATION (THE TRUTH)
# ------------------------------------------------------------------------------

# 1. The Green Lane (Whitelist)
# If a file has this extension, we COPY it. No questions asked. No binary checks.
# This prevents the script from falsely flagging your code as binary.
SAFE_EXTENSIONS="cs|csproj|sln|user|vs|json|xml|html|css|scss|less|js|jsx|ts|tsx|vue|svelte|py|rb|go|rs|java|kt|c|h|cpp|hpp|sh|bash|zsh|yaml|yml|toml|md|txt|sql|graphql|dockerfile|makefile|gradle|properties|editorconfig|gitignore|env|conf|ini|svg"

# 2. The Red Lane (Blacklist)
# Files to NEVER copy (Security/Noise)
IGNORE_FILES="package-lock.json|yarn.lock|Cargo.lock|Gemfile.lock|.DS_Store|Thumbs.db"
SECURITY_FILES="id_rsa|id_dsa|.pem|.key|.p12|secrets"

# 3. Settings
MAX_SIZE_KB=1000
TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'git-copy')
CONTEXT_FILE="${TEMP_DIR}/context.md"

trap "rm -rf $TEMP_DIR" EXIT

# ------------------------------------------------------------------------------
# 🧠 INTELLIGENCE
# ------------------------------------------------------------------------------

# Universal Clipboard
copy_output() {
    if [[ "$OSTYPE" == "darwin"* ]]; then pbcopy
    elif [ -n "${WSL_DISTRO_NAME:-}" ]; then clip.exe
    elif command -v wl-copy >/dev/null; then wl-copy
    elif command -v xclip >/dev/null; then xclip -selection clipboard
    else cat; fi # Fallback to stdout
}

# The "Clean" Tree Generator
# Uses indentation only, no pipes, to save space and reduce visual noise.
generate_clean_tree() {
    sort | awk -F'/' '
    BEGIN { print "." }
    {
        indent = ""
        for (i=1; i<NF; i++) {
            if ($i != p[i]) {
                print indent $i "/"
                # Update previous path
                for (k=i; k<=NF; k++) p[k] = "" 
            }
            indent = indent "  "
        }
        print indent $NF
        split($0, p, "/")
    }'
}

# Language Tagger
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

# 1. Gather Files
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ROOT=$(git rev-parse --show-toplevel)
    # Get all files, respecting .gitignore
    git ls-files -z --exclude-standard -c -o . > "${TEMP_DIR}/raw"
else
    ROOT=$(pwd)
    find . -type f -not -path '*/.*' -print0 > "${TEMP_DIR}/raw"
fi

# 2. Filter & Sort
LIST_FILE="${TEMP_DIR}/list"
xargs -0 -n 1 < "${TEMP_DIR}/raw" | sort > "$LIST_FILE"

# 3. Generate Content
{
    echo "# Project Context"
    echo "- **Root:** \`$ROOT\`"
    echo "- **Generated:** $(date)"
    echo ""
    echo "## Structure"
    echo "\`\`\`text"
    cat "$LIST_FILE" | generate_clean_tree
    echo "\`\`\`"
    echo ""
} > "$CONTEXT_FILE"

COUNT=0
SKIP_BIN=0
SKIP_SIZE=0

while IFS= read -r file; do
    [ -z "$file" ] && continue
    [[ "$(basename "$file")" == "git-copy" ]] && continue
    [ ! -f "$file" ] && continue

    # A. Security Check
    if [[ "$file" =~ $SECURITY_FILES ]]; then
        echo "## File: \`$file\`" >> "$CONTEXT_FILE"
        echo "> 🔒 **CENSORED (Security)**" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        continue
    fi
    
    # B. Noise Check
    if [[ "$file" =~ $IGNORE_FILES ]]; then continue; fi

    # C. Decision Engine
    DO_COPY=false
    EXT="${file##*.}"
    LOWER_EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
    
    # C1. Check Whitelist (The Fix)
    # If the extension is known safe, we skip the binary check entirely.
    if [[ "$SAFE_EXTENSIONS" =~ (^|\|)$LOWER_EXT($|\|) ]]; then
        DO_COPY=true
    else
        # C2. Fallback: Native File Check
        # Only check unknown extensions.
        if file -b --mime "$file" | grep -q "text"; then
            DO_COPY=true
        else
            # Try Mac specific flag
            if file -bI "$file" 2>/dev/null | grep -q "text"; then
                DO_COPY=true
            fi
        fi
    fi

    # D. Execute Decision
    if [ "$DO_COPY" = true ]; then
        # Size Check
        SIZE=$(wc -c < "$file")
        if [ "$SIZE" -gt $((MAX_SIZE_KB * 1024)) ]; then
            echo "## File: \`$file\`" >> "$CONTEXT_FILE"
            echo "> ⚠️ **SKIPPED (Too Large: $((SIZE/1024))KB)**" >> "$CONTEXT_FILE"
            echo "" >> "$CONTEXT_FILE"
            ((SKIP_SIZE++))
        else
            # COPY CONTENT
            ((COUNT++))
            printf "\r\033[0;36mProcessing: $file\033[0m\033[K" >&2
            
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
        echo "> 🤖 **SKIPPED (Binary/Unknown)**" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        ((SKIP_BIN++))
    fi

done < "$LIST_FILE"

# 4. Finalize
printf "\r\033[K" >&2
cat "$CONTEXT_FILE" | copy_output

echo -e "${GREEN}✔ Context Copied!${NC}"
echo -e "📄 Files Included: $COUNT"
echo -e "🗑️  Skipped (Bin): $SKIP_BIN"
echo -e "⚖️  Skipped (Big): $SKIP_SIZE"

EOF

$SUDO chmod +x "$TARGET_PATH"
echo -e "${GREEN}✅ OMNI-COPY INSTALLED.${NC}"
echo "Run 'git copy' to test."
