#!/bin/bash

# ==============================================================================
# 🔮 GOD MODE INSTALLER: git-copy (The Neural Interface)
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
echo -e "${CYAN}  >> INITIALIZING CONTEXT EXTRACTION PROTOCOL <<${NC}"
echo ""

# 1. Permission & Path Check
SUDO=""
if [ ! -w "$INSTALL_DIR" ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
        echo -e "${CYAN}🔒 Elevation required to write to ${INSTALL_DIR}...${NC}"
    else
        echo -e "${RED}💀 Fatal: Cannot write to $INSTALL_DIR and sudo is missing.${NC}"
        echo -e "   Try running as root or changing install path."
        exit 1
    fi
fi

# 2. The Payload (Written in pure Bash 4.0+)
$SUDO tee "$TARGET_PATH" > /dev/null << 'EOF'
#!/usr/bin/env bash

# ==============================================================================
# 🧠 GIT-COPY: GOD MODE (v3.0.0)
# "Give me the code, and I shall move the world."
# ==============================================================================

# Strict Mode: Fail fast, fail loud.
set -o errexit
set -o nounset
set -o pipefail

# Trap cleanup to ensure no temp files are left behind
trap cleanup SIGINT SIGTERM EXIT

# ------------------------------------------------------------------------------
# 🎨 CONSTANTS & CONFIGURATION
# ------------------------------------------------------------------------------
VERSION="3.0.0-GODMODE"
MAX_FILE_SIZE_KB=500     # Files larger than this are summarized, not copied
TOKEN_RATIO=4            # Approx chars per token
TEMP_DIR=$(mktemp -d)
CONTEXT_FILE="${TEMP_DIR}/context.md"

# Colors
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# File Extension Groups (The "Knowledge Graph")
declare -A GROUP_DEFS
GROUP_DEFS[web]="html css scss sass less js jsx ts tsx json svg vue svelte"
GROUP_DEFS[backend]="py rb php pl go rs java cs cpp h c hpp swift kt ex exs sh"
GROUP_DEFS[data]="json yaml yml toml xml csv sql graphql"
GROUP_DEFS[config]="env conf ini dockerfile makefile gemfile package.json cargo.toml go.mod"
GROUP_DEFS[docs]="md txt rst adoc"

# Security Blacklist (Regex patterns to NEVER copy content from)
SECURITY_BLACKLIST="id_rsa|id_dsa|\.pem|\.key|\.env|secrets|credentials"

# ------------------------------------------------------------------------------
# 🛠️ CORE FUNCTIONS
# ------------------------------------------------------------------------------

cleanup() {
    rm -rf "$TEMP_DIR"
}

die() { echo -e "${RED}✖ FATAL: $1${NC}" >&2; exit 1; }
info() { echo -e "${BLUE}ℹ $1${NC}"; }
success() { echo -e "${GREEN}✔ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}" >&2; }

# 1. Universal Clipboard Detection
# Attempts to find any known clipboard utility on the planet.
detect_clipboard() {
    if [ -n "${WSL_DISTRO_NAME:-}" ] && command -v clip.exe >/dev/null; then
        echo "clip.exe" 
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "pbcopy"
    elif command -v wl-copy >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY:-}" ]; then
        echo "wl-copy"
    elif command -v xclip >/dev/null 2>&1; then
        echo "xclip -selection clipboard"
    elif command -v xsel >/dev/null 2>&1; then
        echo "xsel --clipboard --input"
    elif command -v termux-clipboard-set >/dev/null 2>&1; then
        echo "termux-clipboard-set"
    elif [ -e /dev/clipboard ]; then
        echo "cat > /dev/clipboard" # Cygwin
    else
        die "No clipboard detected. Install xclip, wl-copy, or use macOS/WSL."
    fi
}

# 2. Heuristic Language Detection
# Maps filenames to markdown code block tags.
get_lang_tag() {
    local fname="$1"
    local ext="${fname##*.}"
    local lower_name=$(basename "$fname" | tr '[:upper:]' '[:lower:]')

    case "$lower_name" in
        dockerfile) echo "dockerfile"; return ;;
        makefile) echo "makefile"; return ;;
        vimrc) echo "vim"; return ;;
        *.*) ;;
        *) echo "text"; return ;; 
    esac

    case "$ext" in
        js|mjs|cjs) echo "javascript" ;;
        jsx|ts|tsx) echo "typescript" ;;
        py|pyw) echo "python" ;;
        rs) echo "rust" ;;
        go) echo "go" ;;
        java|kt|groovy) echo "java" ;;
        c|h) echo "c" ;;
        cpp|hpp|cc|cxx) echo "cpp" ;;
        cs) echo "csharp" ;;
        sh|bash|zsh) echo "bash" ;;
        html|htm) echo "html" ;;
        css|scss|sass|less) echo "css" ;;
        json|json5) echo "json" ;;
        yaml|yml) echo "yaml" ;;
        xml|csproj|svg) echo "xml" ;;
        sql) echo "sql" ;;
        md|markdown) echo "markdown" ;;
        toml|ini|cfg|conf) echo "ini" ;;
        rb|erb) echo "ruby" ;;
        php) echo "php" ;;
        vue) echo "vue" ;;
        svelte) echo "svelte" ;;
        *) echo "$ext" ;;
    esac
}

# 3. Binary File Detection
# Reads the first few bytes looking for null characters. 
# Much faster than `file` command and works on stripped systems.
is_binary() {
    # If grep finds a null byte in the first 100 lines/bytes, it's binary
    if grep -qP -m 1 '\x00' <(head -c 8000 "$1"); then
        return 0 # True
    fi
    return 1 # False
}

# 4. Pure Bash Tree Generator
# Generates a visual tree without needing the `tree` command installed.
generate_tree() {
    sort | awk -F'/' '
    BEGIN { print "." }
    {
        if (NF == 1) {
            print "├── " $1
        } else {
            for (i=1; i<NF; i++) {
                if ($i != p[i]) {
                    # Print directory
                    for (j=1; j<i; j++) printf "│   "
                    print "├── " $i "/"
                }
            }
            # Print file
            for (j=1; j<NF; j++) printf "│   "
            print "├── " $NF
        }
        split($0, p, "/")
    }' | sed 's/├──/|--/g' 
}

# ------------------------------------------------------------------------------
# 🎮 MAIN EXECUTION FLOW
# ------------------------------------------------------------------------------

# -- Argument Parsing --
declare -a INCLUDE_PATTERNS
USE_ALL=true

if [ $# -gt 0 ]; then
    USE_ALL=false
    for arg in "$@"; do
        if [[ "${GROUP_DEFS[$arg]+found}" ]]; then
            # Expand group alias
            for ext in ${GROUP_DEFS[$arg]}; do INCLUDE_PATTERNS+=("*.$ext"); done
        elif [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            echo -e "${BOLD}Usage:${NC} git-copy [group|extension|file]..."
            echo -e "${DIM}Groups:${NC} ${!GROUP_DEFS[@]}"
            exit 0
        else
            # Specific pattern
            if [[ "$arg" == *"."* ]]; then INCLUDE_PATTERNS+=("$arg"); else INCLUDE_PATTERNS+=("*.$arg"); fi
        fi
    done
fi

# -- Context Discovery --
# Are we in git?
IS_GIT=false
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then IS_GIT=true; fi

# Get Root
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

# -- File Listing Strategy --
LIST_FILE="${TEMP_DIR}/files.txt"

if $IS_GIT; then
    # Git Mode: Respect .gitignore automatically
    git ls-files -z --exclude-standard -c -o . > "${TEMP_DIR}/gitfiles.raw"
    
    # Filter content
    if $USE_ALL; then
        xargs -0 -n 1 < "${TEMP_DIR}/gitfiles.raw" > "$LIST_FILE"
    else
        # Filter based on arguments
        while IFS= read -r -d '' file; do
            MATCH=false
            for pattern in "${INCLUDE_PATTERNS[@]}"; do
                # Match filename or extension
                if [[ "$file" == $pattern || "$(basename "$file")" == $pattern ]]; then
                    MATCH=true; break
                fi
            done
            if $MATCH; then echo "$file" >> "$LIST_FILE"; fi
        done < "${TEMP_DIR}/gitfiles.raw"
    fi
else
    # Fallback Mode: Smart Find
    # Exclude common garbage folders
    find . -type f \
        -not -path '*/.*' \
        -not -path '*/node_modules/*' \
        -not -path '*/vendor/*' \
        -not -path '*/build/*' \
        -not -path '*/dist/*' \
        -not -path '*/__pycache__/*' \
        -print0 | xargs -0 -n 1 | sed 's|^\./||' > "$LIST_FILE"
    
    # Apply filtering if not using all
    if [ "$USE_ALL" = false ]; then
        # (Simplified filtering for find mode - strict match on extension)
        mv "$LIST_FILE" "${TEMP_DIR}/all_files.txt"
        for pattern in "${INCLUDE_PATTERNS[@]}"; do
            # Convert bash wildcard to grep regex (basic)
            pat_clean="${pattern//\*/.*}"
            grep -E "${pat_clean}$" "${TEMP_DIR}/all_files.txt" >> "$LIST_FILE" || true
        done
        sort -u "$LIST_FILE" -o "$LIST_FILE"
    fi
fi

# -- Processing & Formatting --
COUNT=0
TOTAL_BYTES=0
TOTAL_LINES=0

# Header
{
    echo "# Project Context"
    echo "- **Root:** \`$ROOT_DIR\`"
    echo "- **Path:** \`$REL_PREFIX\`"
    echo "- **Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo ""
    echo "## File Tree"
    echo "\`\`\`text"
    cat "$LIST_FILE" | generate_tree
    echo "\`\`\`"
    echo ""
    echo "---"
    echo ""
} > "$CONTEXT_FILE"

# Process Files
while IFS= read -r file; do
    [ -z "$file" ] && continue
    # Skip self
    [[ "$(basename "$file")" == "git-copy" ]] && continue
    
    # Visual Progress
    ((COUNT++))
    printf "\r${CYAN}⚡ Processing file $COUNT...${NC}" >&2

    # 1. Security Check
    if [[ "$file" =~ $SECURITY_BLACKLIST ]]; then
        echo "## File: \`$file\`" >> "$CONTEXT_FILE"
        echo "> 🔒 **CENSORED (Security Sensitive)**" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        warn "Skipping sensitive file: $file"
        continue
    fi

    # 2. Existence Check
    if [ ! -f "$file" ]; then continue; fi

    # 3. Size Check
    FSIZE=$(wc -c < "$file")
    if [ "$FSIZE" -gt $((MAX_FILE_SIZE_KB * 1024)) ]; then
        echo "## File: \`$file\`" >> "$CONTEXT_FILE"
        echo "> ⚠️ **SKIPPED (Too Large: $((FSIZE/1024))KB)**" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        continue
    fi

    # 4. Binary Check
    if is_binary "$file"; then
        echo "## File: \`$file\`" >> "$CONTEXT_FILE"
        echo "> 🤖 **SKIPPED (Binary Detected)**" >> "$CONTEXT_FILE"
        echo "" >> "$CONTEXT_FILE"
        continue
    fi

    # 5. Append Content
    LANG=$(get_lang_tag "$file")
    LINES=$(wc -l < "$file")
    ((TOTAL_LINES+=LINES))
    ((TOTAL_BYTES+=FSIZE))

    echo "## File: \`$file\`" >> "$CONTEXT_FILE"
    echo "\`\`\`$LANG" >> "$CONTEXT_FILE"
    cat "$file" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"
    echo "\`\`\`" >> "$CONTEXT_FILE"
    echo "" >> "$CONTEXT_FILE"

done < "$LIST_FILE"

printf "\r\033[K" >&2

# -- Metrics & Clipboard --
TOKENS=$((TOTAL_BYTES / TOKEN_RATIO))

# Output to clipboard
cat "$CONTEXT_FILE" | eval "$CLIP_CMD"

# Summary
echo -e "${GREEN}${BOLD}✔ Mission Accomplished.${NC}"
echo -e "${DIM}────────────────────────────────────────${NC}"
echo -e "📄 Files:     ${BOLD}${COUNT}${NC}"
echo -e "📝 Lines:     ${BOLD}${TOTAL_LINES}${NC}"
echo -e "💾 Size:      ${BOLD}$((TOTAL_BYTES/1024)) KB${NC}"
echo -e "🧠 Tokens:    ${BOLD}~${TOKENS}${NC} (GPT-4 est.)"
echo -e "${DIM}────────────────────────────────────────${NC}"

if [ "$TOKENS" -gt 128000 ]; then
    warn "Token count is extremely high (~$TOKENS). Might exceed LLM context window."
fi

EOF

# 3. Final Permissions
$SUDO chmod +x "$TARGET_PATH"

echo -e "${GREEN}✅ System Upgrade Complete.${NC}"
echo -e "   Executable: ${BOLD}$TARGET_PATH${NC}"
echo -e "   Usage:      ${CYAN}git-copy [web|backend|*.js]${NC}"
echo ""
