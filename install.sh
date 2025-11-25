#!/bin/bash

# ==============================================================================
# 🔮 GOD MODE INSTALLER: git-copy (Universal MacOS/Linux Fix)
# ==============================================================================

TOOL_NAME="git-copy"
INSTALL_DIR="/usr/local/bin"
TARGET_PATH="$INSTALL_DIR/$TOOL_NAME"

# Visuals
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${PURPLE}   ___  ___  _  _  _____  ____  __  __  ____ ${NC}"
echo -e "${PURPLE}  / __)/ __)( \/ )(  _  )(  _ \(  )(  )(_  _)${NC}"
echo -e "${PURPLE} ( (__( (__  \  /  )(_)(  )___/ )(__)(   )(  ${NC}"
echo -e "${PURPLE}  \___)\___) (__) (_____)(__)  (______) (__) ${NC}"
echo -e "${CYAN}  >> RE-INITIALIZING FOR BASH 3.2 COMPATIBILITY <<${NC}"
echo ""

# 1. Permission Check
SUDO=""
if [ ! -w "$INSTALL_DIR" ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
        echo -e "${CYAN}🔒 Elevation required to write to ${INSTALL_DIR}...${NC}"
    else
        echo -e "${RED}💀 Fatal: Cannot write to $INSTALL_DIR and sudo is missing.${NC}"
        exit 1
    fi
fi

# 2. The Payload (Rewritten for Bash 3.2+ Compatibility)
$SUDO tee "$TARGET_PATH" > /dev/null << 'EOF'
#!/usr/bin/env bash

# ==============================================================================
# 🧠 GIT-COPY: GOD MODE (v3.1.0 - Universal)
# Works on MacOS Bash 3.2 and Modern Linux
# ==============================================================================

set -o errexit
set -o nounset
set -o pipefail

# ------------------------------------------------------------------------------
# 🎨 CONSTANTS
# ------------------------------------------------------------------------------
MAX_FILE_SIZE_KB=500
TOKEN_RATIO=4
TEMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'git-copy')
CONTEXT_FILE="${TEMP_DIR}/context.md"

# Colors
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Security Blacklist (Regex)
SECURITY_BLACKLIST="id_rsa|id_dsa|\.pem|\.key|\.env|secrets|credentials"

# ------------------------------------------------------------------------------
# 🛠️ CORE FUNCTIONS
# ------------------------------------------------------------------------------

# Defined early to prevent "command not found" if script crashes early
cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup SIGINT SIGTERM EXIT

die() { echo -e "${RED}✖ FATAL: $1${NC}" >&2; exit 1; }
info() { echo -e "${BLUE}ℹ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}" >&2; }

# Bash 3.2 Compatible Group Lookup (Replaces declare -A)
get_group_extensions() {
    case "$1" in
        web) echo "html css scss sass less js jsx ts tsx json svg vue svelte" ;;
        backend) echo "py rb php pl go rs java cs cpp h c hpp swift kt ex exs sh" ;;
        data) echo "json yaml yml toml xml csv sql graphql" ;;
        config) echo "env conf ini dockerfile makefile gemfile package.json cargo.toml go.mod" ;;
        docs) echo "md txt rst adoc" ;;
        *) echo "" ;; # Return empty if not found
    esac
}

# Universal Clipboard Detector
detect_clipboard() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "pbcopy"
    elif [ -n "${WSL_DISTRO_NAME:-}" ] && command -v clip.exe >/dev/null; then
        echo "clip.exe"
    elif command -v wl-copy >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY:-}" ]; then
        echo "wl-copy"
    elif command -v xclip >/dev/null 2>&1; then
        echo "xclip -selection clipboard"
    elif command -v xsel >/dev/null 2>&1; then
        echo "xsel --clipboard --input"
    else
        die "No clipboard detected. Use macOS, WSL, or install xclip."
    fi
}

# Heuristic Language Detection
get_lang_tag() {
    local fname="$1"
    local ext="${fname##*.}"
    local lower_name=$(basename "$fname" | tr '[:upper:]' '[:lower:]')

    # Special Filenames
    case "$lower_name" in
        dockerfile) echo "dockerfile"; return ;;
        makefile) echo "makefile"; return ;;
        vimrc) echo "vim"; return ;;
    esac

    # Extensions
    case "$ext" in
        js|mjs|cjs) echo "javascript" ;;
        jsx|ts|tsx) echo "typescript" ;;
        py|pyw) echo "python" ;;
        rs) echo "rust" ;;
        go) echo "go" ;;
        java|kt) echo "java" ;;
        c|h|cpp|hpp|cc) echo "cpp" ;;
        cs) echo "csharp" ;;
        sh|bash|zsh) echo "bash" ;;
        html|htm) echo "html" ;;
        css|scss|sass) echo "css" ;;
        json) echo "json" ;;
        yaml|yml) echo "yaml" ;;
        xml|csproj) echo "xml" ;;
        sql) echo "sql" ;;
        md) echo "markdown" ;;
        *) echo "$ext" ;;
    esac
}

# Binary File Detection (Compatible with non-GNU grep)
is_binary() {
    # Check first 1000 bytes for null character
    # LC_ALL=C forces byte-by-byte comparison which is safer on Mac
    if LC_ALL=C grep -qI -m 1 "" "$1"; then
        return 1 # It is text (grep -I treats binary as non-match)
    else
        # If grep -I thinks it's binary, it might be.
        # But grep -I is tricky. Let's rely on perl if grep fails us, 
        # or just assume text if we can read it.
        # Actually, standard grep -I returns 0 if text, 1 if binary (roughly).
        # Let's use a simpler heuristic for Mac:
        # Check if file has null bytes in first 1KB
        if head -c 1024 "$1" | grep -qP '\x00' 2>/dev/null; then
            return 0 # Binary
        fi
        # Mac grep doesn't always support -P well, try Perl which is on every Mac
        if perl -ne 'exit 1 if /\x00/' <(head -c 1024 "$1"); then
            return 1 # Text (Perl exit 1 means match found? No wait.)
        else
            return 0 # Binary
        fi
    fi
}
# Simpler binary check that works on standard Mac/Linux
is_binary_simple() {
    # If the file contains a null byte in the first 512 bytes, assume binary
    if head -c 512 "$1" | grep -q -F "$(printf '\0')"; then
        return 0 # True, is binary
    fi
    return 1 # False, is text
}

# Pure Bash Tree (Awk based, fast)
generate_tree() {
    sort | awk -F'/' '
    BEGIN { print "." }
    {
        if (NF == 1) {
            print "|-- " $1
        } else {
            for (i=1; i<NF; i++) {
                if ($i != p[i]) {
                    for (j=1; j<i; j++) printf "|   "
                    print "|-- " $i "/"
                }
            }
            for (j=1; j<NF; j++) printf "|   "
            print "|-- " $NF
        }
        split($0, p, "/")
    }'
}

# ------------------------------------------------------------------------------
# 🎮 MAIN EXECUTION
# ------------------------------------------------------------------------------

# -- Argument Parsing --
declare -a INCLUDE_PATTERNS
# In Bash 3.2 arrays are just declare -a
USE_ALL=true

if [ $# -gt 0 ]; then
    USE_ALL=false
    for arg in "$@"; do
        # Check if arg is a group
        GROUP_EXTS=$(get_group_extensions "$arg")
        if [ -n "$GROUP_EXTS" ]; then
            for ext in $GROUP_EXTS; do INCLUDE_PATTERNS+=("*.$ext"); done
        elif [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            echo -e "Usage: git-copy [web|backend|extension]..."
            exit 0
        else
            if [[ "$arg" == *"."* ]]; then INCLUDE_PATTERNS+=("$arg"); else INCLUDE_PATTERNS+=("*.$arg"); fi
        fi
    done
fi

# -- Context Discovery --
IS_GIT=false
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then IS_GIT=true; fi

if $IS_GIT; then
    ROOT_DIR=$(git rev-parse --show-toplevel)
    REL_PREFIX=$(git rev-parse --show-prefix)
    [ -z "$REL_PREFIX" ] && REL_PREFIX="./"
else
    ROOT_DIR=$(pwd)
    REL_PREFIX="./"
fi

info "Scanning context at: ${BOLD}${REL_PREFIX}${NC}"
CLIP_CMD=$(detect_clipboard)
LIST_FILE="${TEMP_DIR}/files.txt"

# -- File Listing --
if $IS_GIT; then
    # Git Mode
    git ls-files -z --exclude-standard -c -o . > "${TEMP_DIR}/gitfiles.raw"
    
    if $USE_ALL; then
        xargs -0 -n 1 < "${TEMP_DIR}/gitfiles.raw" > "$LIST_FILE"
    else
        # Filter (Bash 3.2 friendly loop)
        while IFS= read -r -d '' file; do
            MATCH=false
            for pattern in "${INCLUDE_PATTERNS[@]}"; do
                # Wildcard matching
                if [[ "$file" == $pattern || "$(basename "$file")" == $pattern ]]; then
                    MATCH=true; break
                fi
            done
            if $MATCH; then echo "$file" >> "$LIST_FILE"; fi
        done < "${TEMP_DIR}/gitfiles.raw"
    fi
else
    # Find Mode (Mac compatible)
    find . -type f \
        -not -path '*/.*' \
        -not -path '*/node_modules/*' \
        -not -path '*/bin/*' \
        -not -path '*/obj/*' \
        -print0 | xargs -0 -n 1 | sed 's|^\./||' > "$LIST_FILE"
    
    # Simple filter for non-git mode (if needed)
    if [ "$USE_ALL" = false ]; then
        mv "$LIST_FILE" "${TEMP_DIR}/all_files.txt"
        touch "$LIST_FILE"
        for pattern in "${INCLUDE_PATTERNS[@]}"; do
            # Grep filtering (basic)
            CLEAN_PAT="${pattern//\*/}"
            grep "$CLEAN_PAT" "${TEMP_DIR}/all_files.txt" >> "$LIST_FILE" || true
        done
        sort -u "$LIST_FILE" -o "$LIST_FILE"
    fi
fi

# -- Processing --
COUNT=0
TOTAL_BYTES=0
TOTAL_LINES=0

# Prepare Header
{
    echo "# Project Context"
    echo "- **Root:** \`$ROOT_DIR\`"
    echo "- **Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo ""
    echo "## Structure"
    echo "\`\`\`text"
    cat "$LIST_FILE" | generate_tree
    echo "\`\`\`"
    echo ""
} > "$CONTEXT_FILE"

# Loop files
while IFS= read -r file; do
    [ -z "$file" ] && continue
    [[ "$(basename "$file")" == "git-copy" ]] && continue
    
    ((COUNT++))
    printf "\r${CYAN}⚡ Processing file $COUNT...${NC}" >&2

    if [ ! -f "$file" ]; then continue; fi

    # Security Censorship
    if [[ "$file" =~ $SECURITY_BLACKLIST ]]; then
        echo "## File: \`$file\`" >> "$CONTEXT_FILE"
        echo "> 🔒 **CENSORED (Security)**" >> "$CONTEXT_FILE"
        continue
    fi

    # Binary Check
    if is_binary_simple "$file"; then
        echo "## File: \`$file\`" >> "$CONTEXT_FILE"
        echo "> 🤖 **SKIPPED (Binary)**" >> "$CONTEXT_FILE"
        continue
    fi

    # Content
    FSIZE=$(wc -c < "$file")
    
    # Large file check
    if [ "$FSIZE" -gt $((MAX_FILE_SIZE_KB * 1024)) ]; then
        echo "## File: \`$file\`" >> "$CONTEXT_FILE"
        echo "> ⚠️ **SKIPPED (Too Large)**" >> "$CONTEXT_FILE"
        continue
    fi

    LANG=$(get_lang_tag "$file")
    ((TOTAL_BYTES+=FSIZE))
    
    echo "## File: \`$file\`" >> "$CONTEXT_FILE"
    echo "\`\`\`$LANG" >> "$CONTEXT_FILE"
    cat "$file" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"
    echo "\`\`\`" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"

done < "$LIST_FILE"

printf "\r\033[K" >&2

# Final Copy
TOKENS=$((TOTAL_BYTES / TOKEN_RATIO))
cat "$CONTEXT_FILE" | eval "$CLIP_CMD"

echo -e "${GREEN}${BOLD}✔ Copied to Clipboard!${NC}"
echo -e "📄 Files: ${BOLD}${COUNT}${NC} | 🧠 Tokens: ${BOLD}~${TOKENS}${NC}"
EOF

# 3. Finalize
$SUDO chmod +x "$TARGET_PATH"
echo -e "${GREEN}✅ Installation Complete (Mac/Linux Compatible).${NC}"
echo -e "Run ${BOLD}git-copy${NC} to use."
