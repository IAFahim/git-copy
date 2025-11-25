#!/bin/bash

# ==============================================================================
# 🌌 SINGULARITY INSTALLER: git-copy
# The final word in context extraction. Universal. Optimized.
# ==============================================================================

TOOL_NAME="git-copy"
INSTALL_DIR="/usr/local/bin"
TARGET_PATH="$INSTALL_DIR/$TOOL_NAME"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${PURPLE}   ___  __  ____  ____  ____  ____  __  ${NC}"
echo -e "${PURPLE}  / __)(  )(  _ \(_  _)(  __)(_  _)(  ) ${NC}"
echo -e "${PURPLE} ( (_-. )(  )   /  )(   ) _)   )(   )(  ${NC}"
echo -e "${PURPLE}  \___/(__)(_)\_) (__) (____) (__) (__) ${NC}"
echo -e "${CYAN}  >> INSTALLING SINGULARITY EDITION <<${NC}"

# 1. Elevation Check
if [ ! -w "$INSTALL_DIR" ]; then
    if command -v sudo >/dev/null 2>&1; then SUDO="sudo"; else
        echo -e "${RED}💀 Fatal: Need root access to install to $INSTALL_DIR${NC}"; exit 1
    fi
else SUDO=""; fi

# 2. The Payload
$SUDO tee "$TARGET_PATH" > /dev/null << 'EOF'
#!/usr/bin/env bash

# ==============================================================================
# 🧠 GIT-COPY: SINGULARITY EDITION (v4.0.0)
# - Universal (Perl/Bash 3.2+)
# - Token Optimized Tree
# - Smart Noise Reduction
# ==============================================================================

set -o nounset
set -o pipefail
# set -o errexit # Disabled to allow soft-fails on file read errors

# ------------------------------------------------------------------------------
# ⚙️ CONFIGURATION
# ------------------------------------------------------------------------------
MAX_FILE_SIZE_KB=1024
TOKEN_RATIO=4

# 🗑️ NOISE FILTER
# Files that waste tokens but provide no logic value
IGNORE_PATTERNS="package-lock.json|yarn.lock|pnpm-lock.yaml|Cargo.lock|Gemfile.lock|composer.lock|mix.lock|\.map$|\.min\.js$|\.min\.css$|\.svg$"

# 🔒 SECURITY FILTER
# Files that effectively destroy your security if shared
SECURITY_BLACKLIST="id_rsa|id_dsa|\.pem|\.key|\.env(\..+)?$|secrets|credentials|\.p12"

# Temp setup
TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'git-copy')
CONTEXT_FILE="${TEMP_DIR}/context.md"

# ------------------------------------------------------------------------------
# 🛠️ POLYGLOT FUNCTIONS (Universal Compatibility)
# ------------------------------------------------------------------------------

cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup SIGINT SIGTERM EXIT

# 1. Universal Clipboard
# Tries every known clipboard tool in existence.
copy_to_clipboard() {
    if [[ "$OSTYPE" == "darwin"* ]]; then pbcopy
    elif [ -n "${WSL_DISTRO_NAME:-}" ]; then clip.exe
    elif command -v wl-copy >/dev/null 2>&1; then wl-copy
    elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then xsel --clipboard --input
    elif command -v putclip >/dev/null 2>&1; then putclip # Cygwin
    else echo -e "\033[0;31m✖ No clipboard found. Output printed to stdout.\033[0m" >&2; cat; fi
}

# 2. Universal Binary Detector (Perl 5)
# Works on Mac, Linux, Windows Git Bash. 100% Reliable.
is_binary() {
    perl -e '
        exit 1 unless -f $ARGV[0];
        open(my $f, "<", $ARGV[0]) or exit 1;
        read($f, my $buf, 1024);
        exit ($buf =~ /\x00/ ? 0 : 1); # Returns 0 (true) if binary
    ' "$1"
}

# 3. Compact Tree Generator (Token Optimized)
# Uses 2-space indentation instead of pipes to save horizontal tokens.
generate_compact_tree() {
    sort | awk -F'/' '
    BEGIN { print "." }
    {
        indent = ""
        # Calculate indentation based on depth
        for (i=1; i<NF; i++) {
            if ($i != p[i]) {
                # New Directory
                print indent $i "/"
            }
            indent = indent "  " # 2 spaces per level
        }
        print indent $NF
        split($0, p, "/")
    }'
}

# 4. Language Detector
get_lang() {
    local ext="${1##*.}"
    local name=$(basename "$1" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$name" == "dockerfile" ]]; then echo "dockerfile"; return; fi
    if [[ "$name" == "makefile" ]]; then echo "makefile"; return; fi
    
    case "$ext" in
        js|jsx|ts|tsx|mjs) echo "javascript" ;;
        cs|csproj) echo "csharp" ;;
        py) echo "python" ;;
        go) echo "go" ;;
        rs) echo "rust" ;;
        java|kt) echo "java" ;;
        c|h|cpp|hpp) echo "cpp" ;;
        html|vue|svelte) echo "html" ;;
        css|scss|sass) echo "css" ;;
        json|json5) echo "json" ;;
        yaml|yml) echo "yaml" ;;
        sh|bash|zsh) echo "bash" ;;
        md) echo "markdown" ;;
        sql) echo "sql" ;;
        *) echo "$ext" ;;
    esac
}

# ------------------------------------------------------------------------------
# 🚀 EXECUTION
# ------------------------------------------------------------------------------

# -- Argument Parsing --
declare -a INCLUDE_PATTERNS
USE_ALL=true

if [ $# -gt 0 ]; then
    USE_ALL=false
    for arg in "$@"; do
        # Group Expansion
        case "$arg" in
            web) P="html css scss js jsx ts tsx json vue svelte" ;;
            backend) P="py rb php go rs java cs cpp c h swift kt" ;;
            config) P="env conf ini dockerfile makefile json yaml toml" ;;
            *) P="" ;;
        esac
        
        if [ -n "$P" ]; then
            for ext in $P; do INCLUDE_PATTERNS+=("*.$ext"); done
        else
            if [[ "$arg" == *"."* ]]; then INCLUDE_PATTERNS+=("$arg"); else INCLUDE_PATTERNS+=("*.$arg"); fi
        fi
    done
fi

# -- Discovery --
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ROOT=$(git rev-parse --show-toplevel)
    # Use git ls-files to respect .gitignore
    git ls-files -z --exclude-standard -c -o . > "${TEMP_DIR}/raw"
else
    ROOT=$(pwd)
    # Fallback for non-git folders
    find . -type f -not -path '*/.*' -not -path '*/node_modules/*' -print0 > "${TEMP_DIR}/raw"
fi

# -- Filtering --
LIST_FILE="${TEMP_DIR}/list"
touch "$LIST_FILE"

while IFS= read -r -d '' file; do
    # Strip relative prefix if present
    clean_file="${file#./}"
    
    # 1. Check User Filters
    if [ "$USE_ALL" = false ]; then
        MATCH=false
        for pat in "${INCLUDE_PATTERNS[@]}"; do
            # Simple wildcard matching logic
            if [[ "$clean_file" == $pat || "$(basename "$clean_file")" == $pat ]]; then
                MATCH=true; break
            fi
        done
        if [ "$MATCH" = false ]; then continue; fi
    fi

    echo "$clean_file" >> "$LIST_FILE"
done < "${TEMP_DIR}/raw"

# -- Content Generation --
COUNT=0
TOTAL_BYTES=0

# Header
{
    echo "# Context"
    echo "- **Root:** \`$ROOT\`"
    echo "- **Time:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo ""
    echo "## Structure"
    echo "\`\`\`text"
    # Generate the Compact Tree
    cat "$LIST_FILE" | generate_compact_tree
    echo "\`\`\`"
    echo ""
} > "$CONTEXT_FILE"

# Process Files
while IFS= read -r file; do
    [ -z "$file" ] && continue
    [[ "$(basename "$file")" == "git-copy" ]] && continue
    
    if [ ! -f "$file" ]; then continue; fi

    ((COUNT++))
    printf "\r\033[0;36m⚡ Processing file $COUNT...\033[0m" >&2

    # 1. Security Check
    if [[ "$file" =~ $SECURITY_BLACKLIST ]]; then
        echo "## File: \`$file\`" >> "$CONTEXT_FILE"
        echo "> 🔒 **CENSORED (Security)**" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        continue
    fi
    
    # 2. Noise Check
    if [[ "$file" =~ $IGNORE_PATTERNS ]]; then
        # Silently skip lock files to save massive space
        continue
    fi

    # 3. Binary Check
    if is_binary "$file"; then
        echo "## File: \`$file\`" >> "$CONTEXT_FILE"
        echo "> 🤖 **SKIPPED (Binary)**" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        continue
    fi

    # 4. Size Check
    SIZE=$(wc -c < "$file")
    if [ "$SIZE" -gt $((MAX_FILE_SIZE_KB * 1024)) ]; then
        echo "## File: \`$file\`" >> "$CONTEXT_FILE"
        echo "> ⚠️ **SKIPPED (Too Large: $((SIZE/1024))KB)**" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        continue
    fi

    ((TOTAL_BYTES+=SIZE))
    LANG=$(get_lang "$file")

    echo "## File: \`$file\`" >> "$CONTEXT_FILE"
    echo "\`\`\`$LANG" >> "$CONTEXT_FILE"
    cat "$file" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"
    echo "\`\`\`" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"

done < "$LIST_FILE"

printf "\r\033[K" >&2

# Final Output
cat "$CONTEXT_FILE" | copy_to_clipboard

# Summary
TOKENS=$((TOTAL_BYTES / TOKEN_RATIO))
echo -e "\033[0;32m\033[1m✔ Copied to Clipboard!\033[0m"
echo -e "\033[2mFiles:  $COUNT"
echo -e "Tokens: ~$TOKENS\033[0m"

EOF

# 3. Finalize
$SUDO chmod +x "$TARGET_PATH"
echo -e "${GREEN}✅ Installation Complete.${NC}"
echo -e "Use: ${BOLD}git copy [web|backend|*.js]${NC}"
