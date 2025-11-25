#!/bin/bash

# ==============================================================================
# 🔮 GOD MODE INSTALLER: git-copy
# ==============================================================================

INSTALL_DIR="/usr/local/bin"
TOOL_NAME="git-copy"
TARGET_PATH="$INSTALL_DIR/$TOOL_NAME"

# Colors for the installer
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}Initializing Neural Interface... (Installing git-copy)${NC}"

# 1. Permission Check
SUDO=""
if [ ! -w "$INSTALL_DIR" ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
        echo -e "${CYAN}Requesting root access to write to ${INSTALL_DIR}...${NC}"
    else
        echo -e "${RED}Error: Cannot write to $INSTALL_DIR and sudo not found.${NC}"
        exit 1
    fi
fi

# 2. Write the Ultimate Script
$SUDO tee "$TARGET_PATH" > /dev/null << 'EOF'
#!/usr/bin/env bash

# 🛡️ STRICT MODE
set -o errexit  # Exit on error
set -o nounset  # Exit on unset variables
set -o pipefail # Fail if any command in pipe fails
# set -o xtrace # Uncomment for debugging

# ==============================================================================
# 🧠 CONFIGURATION & CONSTANTS
# ==============================================================================
VERSION="2.0.0 (God Mode)"
MAX_FILE_SIZE_KB=1024  # Skip files larger than 1MB to prevent clipboard crashes

# ANSI Colors
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Default File Groups (The "Knowledge Base")
declare -A GROUP_DEFS
GROUP_DEFS[web]="html css scss sass less js jsx ts tsx json svg"
GROUP_DEFS[backend]="py rb php pl go rs java cs cpp h c hpp swift kt"
GROUP_DEFS[config]="json yaml yml toml xml ini env conf sql"
GROUP_DEFS[build]="Dockerfile Makefile Gemfile package.json cargo.toml go.mod csproj gradle"
GROUP_DEFS[docs]="md txt rst"

# ==============================================================================
# 🔧 CORE FUNCTIONS
# ==============================================================================

die() { echo -e "${RED}✖ $1${NC}" >&2; exit 1; }
log() { echo -e "${CYAN}ℹ${NC} $1"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}" >&2; }

# 1. UNIVERSAL CLIPBOARD DETECTOR
# Detects WSL, Wayland, X11, macOS, Termux, Cygwin
detect_clipboard() {
    if [ -n "${WSL_DISTRO_NAME:-}" ] && command -v clip.exe >/dev/null; then
        echo "clip.exe" # WSL Windows Clipboard
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
        die "No clipboard utility found. Install xclip, wl-copy, or use macOS/WSL."
    fi
}

# 2. HEURISTIC LANGUAGE DETECTOR
get_lang() {
    local ext="${1##*.}"
    local name=$(basename "$1")
    name="${name,,}" # to lowercase

    case "$name" in
        dockerfile) echo "dockerfile"; return ;;
        makefile) echo "makefile"; return ;;
        package.json) echo "json"; return ;;
        *.*) ;;
        *) echo "text"; return ;; # No extension
    esac

    case "$ext" in
        js|jsx|mjs|cjs) echo "javascript" ;;
        ts|tsx) echo "typescript" ;;
        py|pyw) echo "python" ;;
        rs) echo "rust" ;;
        go) echo "go" ;;
        java) echo "java" ;;
        c|h) echo "c" ;;
        cpp|hpp|cc|cxx) echo "cpp" ;;
        cs) echo "csharp" ;;
        sh|bash|zsh) echo "bash" ;;
        html|htm) echo "html" ;;
        css) echo "css" ;;
        scss|sass) echo "scss" ;;
        json) echo "json" ;;
        yaml|yml) echo "yaml" ;;
        xml|csproj|xaml) echo "xml" ;;
        sql) echo "sql" ;;
        md) echo "markdown" ;;
        toml) echo "toml" ;;
        *) echo "$ext" ;;
    esac
}

# 3. BINARY FILE DETECTOR (Fast Heuristic)
is_binary() {
    # Check for null bytes in the first 100 bytes
    if grep -qP -m 1 '\x00' <(head -c 100 "$1"); then
        return 0 # True (is binary)
    fi
    return 1 # False (is text)
}

# 4. DEPENDENCY-FREE TREE GENERATOR (Pure Bash/Awk)
# Generates a visual tree from a list of file paths without needing 'tree' installed
generate_tree() {
    sort | awk -F'/' '
    BEGIN { print "." }
    {
        if (NF == 1) {
            print "├── " $1
        } else {
            for (i=1; i<NF; i++) {
                if ($i != p[i]) {
                    # New directory detected
                    for (j=i; j<NF; j++) {
                        printf "%s", (j==i ? "├── " : "│   ")
                    }
                    print $i "/"
                }
                # Indentation for files
                printf "%s", (i==1 ? "" : "│   ")
            }
            print "├── " $NF
        }
        split($0, p, "/")
    }' | sed 's/├──/|--/g' # optional: adjust ascii style
}

# ==============================================================================
# 🎮 MAIN EXECUTION
# ==============================================================================

# -- ARG PARSING --
declare -a EXTENSIONS
MODE="default"

if [ $# -eq 0 ]; then
    # No args: Add everything safely
    for group in "${!GROUP_DEFS[@]}"; do
        for ext in ${GROUP_DEFS[$group]}; do EXTENSIONS+=("*.$ext"); done
    done
    EXTENSIONS+=("Dockerfile" "Makefile" "package.json")
else
    for arg in "$@"; do
        if [[ "${GROUP_DEFS[$arg]+found}" ]]; then
            # Argument matches a predefined group
            for ext in ${GROUP_DEFS[$arg]}; do EXTENSIONS+=("*.$ext"); done
        elif [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
            echo -e "${BOLD}Usage:${NC} git-copy [group|extension]..."
            echo -e "Groups: web, backend, config, build, docs"
            exit 0
        else
            # Argument is a specific extension or file
            if [[ "$arg" == *"."* ]]; then EXTENSIONS+=("$arg"); else EXTENSIONS+=("*.$arg"); fi
        fi
    done
fi

# -- GIT CONTEXT --
# Ensure we are in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    die "Not inside a Git repository."
fi

# Get current folder relative to git root for display purposes
REL_PREFIX=$(git rev-parse --show-prefix) 
[ -z "$REL_PREFIX" ] && REL_PREFIX="./"

echo -e "${BLUE}🔍 Scanning context starting from: ${BOLD}${REL_PREFIX}${NC}"

CLIP_CMD=$(detect_clipboard)
TEMP_FILE=$(mktemp)
LIST_FILE=$(mktemp)

# -- FILE DISCOVERY --
# 1. Use 'git ls-files -z .' to safely handle all characters (even newlines)
# 2. '.' ensures we only grab files DEEP from current location
# 3. Filter by extensions
git ls-files -z . | while IFS= read -r -d '' file; do
    # Check strict extension match
    MATCH=false
    for pattern in "${EXTENSIONS[@]}"; do
        # Use bash glob matching
        if [[ "$file" == $pattern || "$(basename "$file")" == $pattern ]]; then
            MATCH=true
            break
        fi
    done
    
    if $MATCH; then
        # Safety check: Ignore self
        if [[ "$(basename "$file")" == "git-copy" ]]; then continue; fi
        # Safety check: File existence (git index vs fs)
        if [ ! -f "$file" ]; then continue; fi
        
        printf "%s\0" "$file" >> "$LIST_FILE"
    fi
done

# Check if we found anything
if [ ! -s "$LIST_FILE" ]; then
    rm "$TEMP_FILE" "$LIST_FILE"
    die "No matching files found in this directory context."
fi

# -- CONTENT GENERATION --
COUNT=0
TOTAL_LINES=0
TOTAL_BYTES=0

# Use a spinner while processing
SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

{
    echo "# Context: ${REL_PREFIX}"
    echo "# Generated: $(date)"
    echo ""
} >> "$TEMP_FILE"

while IFS= read -r -d '' file; do
    ((COUNT++))
    
    # Spinner Visual
    SP_CHAR=${SPINNER:((COUNT%10)):1}
    printf "\r${CYAN}${SP_CHAR} Processing file ${COUNT}...${NC}" >&2

    # 1. Size Check
    FILE_SIZE=$(wc -c < "$file")
    if [ "$FILE_SIZE" -gt $((MAX_FILE_SIZE_KB * 1024)) ]; then
        echo "## File: \`$file\` (SKIPPED - Too Large > ${MAX_FILE_SIZE_KB}KB)" >> "$TEMP_FILE"
        continue
    fi

    # 2. Binary Check
    if is_binary "$file"; then
        echo "## File: \`$file\` (SKIPPED - Binary Detected)" >> "$TEMP_FILE"
        continue
    fi

    # 3. Append Content
    LANG=$(get_lang "$file")
    LINES=$(wc -l < "$file")
    ((TOTAL_LINES+=LINES))
    ((TOTAL_BYTES+=FILE_SIZE))

    echo "## File: \`$file\`" >> "$TEMP_FILE"
    echo "\`\`\`$LANG" >> "$TEMP_FILE"
    cat "$file" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    echo "\`\`\`" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"

done < "$LIST_FILE"

printf "\r\033[K" >&2 # Clear line

# -- TREE GENERATION --
echo "---" >> "$TEMP_FILE"
echo "# Project Structure" >> "$TEMP_FILE"
echo "\`\`\`text" >> "$TEMP_FILE"
# xargs -0 handles the null-terminated list
xargs -0 -n 1 < "$LIST_FILE" | generate_tree >> "$TEMP_FILE"
echo "\`\`\`" >> "$TEMP_FILE"

# -- TOKEN ESTIMATION --
# Rough estimate: 1 token ~= 4 chars of code
EST_TOKENS=$((TOTAL_BYTES / 4))

# -- CLIPBOARD & SUMMARY --
cat "$TEMP_FILE" | eval "$CLIP_CMD"

# Cleanup
rm "$TEMP_FILE" "$LIST_FILE"

echo -e "${GREEN}${BOLD}✓ Copied to Clipboard!${NC}"
echo -e "${DIM}----------------------------------------${NC}"
echo -e "📂 Files:   ${BOLD}${COUNT}${NC}"
echo -e "📝 Lines:   ${BOLD}${TOTAL_LINES}${NC}"
echo -e "🧠 Tokens:  ${BOLD}~${EST_TOKENS}${NC} (Est.)"
echo -e "${DIM}----------------------------------------${NC}"
EOF

# 3. Finalize
$SUDO chmod +x "$TARGET_PATH"
echo -e "${GREEN}✅ Installation Complete!${NC}"
echo -e "Run ${BOLD}git copy${NC} in any folder."
