#!/usr/bin/env bash

set -o nounset
set -o pipefail

TOOL_NAME="git-copy"
INSTALL_DIR="/usr/local/bin"
TARGET_PATH="$INSTALL_DIR/$TOOL_NAME"

# Visuals
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${PURPLE}>> INSTALLING GIT-COPY v16.2 (CROSS-PLATFORM EDITION) <<${NC}"

# Permissions Check
CMD_PREFIX=""
if [ ! -w "$INSTALL_DIR" ]; then CMD_PREFIX="sudo"; fi

# Payload Container
TMP_PAYLOAD=$(mktemp)

cat > "$TMP_PAYLOAD" << 'EOF'
#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# ⚡ GIT-COPY | v16.2 | Cross-Platform Edition
# ------------------------------------------------------------------------------
set -o nounset
set -o pipefail

# --- HELP ---
show_help() {
    cat << 'HELP_EOF'

GIT-COPY | v16.2 | Cross-Platform Edition

USAGE:
    git copy [OPTIONS] [FILTERS] [EXCLUDES]

OPTIONS:
    --help, -h          Show this help message

FILTERS:
    <extension>         Copy only files with specified extensions (e.g., js py)
    <preset>            Use predefined filter preset

PRESETS:
    web                 html, css, js, ts, jsx, tsx, json, svg, vue, svelte
    backend             py, rb, php, go, rs, java, cs, cpp, swift, kt
    dotnet              cs, razor, csproj, json, http, xaml
    unity               cs, shader, glsl, asmdef, uss, uxml, json, yaml
    java                java, kt, scala
    cpp                 c, h, cpp, hpp, rs, go, swift
    script              py, rb, php, lua, sh, ps1
    data                sql, xml, json, yaml, toml, md, csv
    config              env, conf, ini, Dockerfile, Makefile
    docs                md, txt, rst, adoc

EXCLUDES:
    -<path>             Exclude folder or path (e.g., -node_modules -tests)
                        Note: Use quotes for paths with spaces (e.g., -"my folder")
    --exclude <path>    Alternative exclude syntax

EXAMPLES:
    git copy                              Copy all tracked files
    git copy js                           Copy only .js files
    git copy web                          Copy all web-related files
    git copy -node_modules                Exclude node_modules folder
    git copy js -tests                    Copy .js files, exclude tests folder
    git copy web -dist -build             Copy web files, exclude build folders
    git copy --exclude src/legacy         Exclude specific path

HELP_EOF
    exit 0
}

# Check for help flag
for arg in "$@"; do
    if [[ "$arg" == "--help" ]] || [[ "$arg" == "-h" ]]; then
        show_help
    fi
done

# --- CONFIG ---
MAX_SIZE=1048576

# Parse arguments - separate exclude paths from filter args
FILTER_ARGS=""
EXCLUDE_PATHS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --exclude)
            shift
            if [[ $# -gt 0 ]]; then
                EXCLUDE_PATHS="${EXCLUDE_PATHS}${EXCLUDE_PATHS:+|}$1"
                shift
            fi
            ;;
        -*)
            # Check if it looks like a path (contains / or is a valid folder name)
            if [[ "$1" =~ ^-.+$ ]]; then
                # Exclude path syntax: -path/to/exclude
                EXCLUDE_PATHS="${EXCLUDE_PATHS}${EXCLUDE_PATHS:+|}${1#-}"
                shift
            else
                # It's a flag we don't recognize, skip it
                shift
            fi
            ;;
        *)
            FILTER_ARGS="$FILTER_ARGS $1"
            shift
            ;;
    esac
done

# Pass arguments to Perl via ENV
export GIT_COPY_ARGS="$FILTER_ARGS"
export GIT_COPY_EXCLUDE="$EXCLUDE_PATHS"

# --- EXECUTION ---
TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'git-copy')
trap "rm -rf $TMP_DIR" EXIT
RESULT_FILE="${TMP_DIR}/result.md"

# 1. DISCOVERY
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ROOT=$(git rev-parse --show-toplevel)
    cmd=(git ls-files -z --cached --others --exclude-standard)
else
    ROOT=$(pwd)
    cmd=(find . -type f -not -path '*/.*' -print0)
fi

echo -e "\033[0;36mProcessing...\033[0m" >&2

# 2. PERL ENGINE
"${cmd[@]}" | perl -0 -ne '
    BEGIN {
        $max_size = '$MAX_SIZE';
        
        # --- PRESETS ---
        %presets = (
            "web"     => "html|htm|css|scss|sass|less|js|jsx|ts|tsx|json|svg|vue|svelte",
            "backend" => "py|rb|php|pl|go|rs|java|cs|cpp|h|c|hpp|swift|kt|ex|exs|sh",
            "dotnet"  => "cs|razor|csproj|json|http|xaml",
            "unity"   => "cs|shader|cginc|hlsl|glsl|asmdef|asmref|uss|uxml|json|yaml",
            "java"    => "java|kt|kts|scala",
            "cpp"     => "c|h|cpp|cc|cxx|hpp|hxx|rs|go|swift",
            "script"  => "py|rb|php|pl|pm|lua|sh|bash|zsh",
            "data"    => "sql|xml|json|yaml|yml|toml|ini|md|csv|graphql",
            "config"  => "env|conf|ini|Dockerfile|Makefile|Gemfile|package\.json|cargo\.toml|go\.mod",
            "build"   => "Dockerfile|Makefile|Gemfile|package\.json",
            "docs"    => "md|txt|rst|adoc"
        );

        # --- ARGS ---
        $args = $ENV{GIT_COPY_ARGS};
        $filter_active = 0;
        $filter_re = "";

        if ($args =~ /\S/) {
            $filter_active = 1;
            @requests = split(/\s+/, lc($args));
            @patterns = ();
            foreach $req (@requests) {
                if (exists $presets{$req}) { push @patterns, $presets{$req}; }
                else { $req =~ s/^\.//; push @patterns, $req; }
            }
            $joined = join("|", @patterns);
            $filter_re = qr/(\.($joined)$)|(^($joined)$)/i;
        }

        # --- EXCLUDE PATHS ---
        $exclude_paths = $ENV{GIT_COPY_EXCLUDE};
        $exclude_active = 0;
        @exclude_list = ();
        
        if ($exclude_paths ne "") {
            $exclude_active = 1;
            @exclude_list = split(/\|/, $exclude_paths);
            # Normalize paths - remove leading ./ and trailing /
            for (@exclude_list) {
                s{^\.?/+}{};
                s{/+$}{};
            }
        }

        # Regex
        # Added \.meta$ to the end to drop Unity meta files
        $ignore_re = qr/package-lock\.json|yarn\.lock|Cargo\.lock|\.DS_Store|Thumbs\.db|\.git\/|\.png$|\.jpg$|\.jpeg$|\.gif$|\.ico$|\.woff2?$|\.pdf$|\.exe$|\.bin$|\.pyc$|\.dll$|\.pdb$|\.min\.js$|\.min\.css$|\.meta$/i;
        
        $sec_re = qr/id_rsa|id_dsa|\.pem|\.key|\.p12|\.env|secrets|credentials/i;

        @files = ();
        $total_bytes = 0;
        $count = 0;
    }

    chomp; 
    $f = $_;
    
    # Clean ./ prefix from find
    $f =~ s/^\.\///;

    # Filter
    next if ($f =~ $ignore_re);
    next unless (-f $f);
    
    # Check exclude paths
    if ($exclude_active) {
        $should_exclude = 0;
        foreach $exclude (@exclude_list) {
            # Check if file path starts with exclude path
            if ($f =~ /^\Q$exclude\E(\/|$)/) {
                $should_exclude = 1;
                last;
            }
        }
        next if $should_exclude;
    }
    
    if ($filter_active) {
        $base = $f; $base =~ s{.*/}{}; 
        next unless ($base =~ $filter_re);
    }

    push @files, $f;

    # Content Checks
    if ($f =~ $sec_re) { next; } 
    if (-B $f) { next; }
    $size = -s $f;
    if ($size > $max_size || $size == 0) { next; }

    # Lang
    $ext = $f; $ext =~ s/.*\.//;
    $lang = $ext;
    %map = (
        "js" => "javascript", "ts" => "typescript", "py" => "python",
        "cs" => "csharp", "sh" => "bash", "md" => "markdown", 
        "h" => "c", "hpp" => "cpp", "razor" => "html", "vue" => "html",
        "shader" => "glsl", "cginc" => "glsl", "hlsl" => "glsl", "uss" => "css", "uxml" => "xml"
    );
    $lang = $map{lc($ext)} if exists $map{lc($ext)};

    # --- RAW STREAM (No Line Numbers) ---
    print "## File: $f\n```$lang\n";
    if (open(my $fh, "<", $f)) {
        while(<$fh>) { print $_; }
        close($fh);
        $count++;
        $total_bytes += $size;
    }
    print "```\n\n";

    END {
        # --- FLAT FILE LIST ---
        print "\n_Project Structure:_\n";
        print "```text\n";
        
        # Simple sorted list of paths
        foreach $path (sort @files) {
            print "$path\n";
        }
        print "```\n";

        # Stats
        $tokens = int($total_bytes / 4);
        if ($total_bytes < 1024) { $hsize = sprintf("%d B", $total_bytes); }
        elsif ($total_bytes < 1048576) { $hsize = sprintf("%.2f KB", $total_bytes/1024); }
        else { $hsize = sprintf("%.2f MB", $total_bytes/1048576); }
        print STDERR "STATS|$count|$hsize|$tokens\n";
    }
' > "$RESULT_FILE" 2> "${TMP_DIR}/stats"

# 3. CLIPBOARD
copy_to_clipboard() {
    local input_file="$1"
    if [ -n "${SSH_TTY:-}" ] || [ -n "${TMUX:-}" ]; then
        local data=$(base64 < "$input_file" | tr -d '\n')
        printf "\033]52;c;%s\007" "$data" > /dev/tty 2>/dev/null || true
    fi
    if [[ "$OSTYPE" == "darwin"* ]]; then pbcopy < "$input_file"
    elif [ -n "${WSL_DISTRO_NAME:-}" ]; then clip.exe < "$input_file"
    elif command -v wl-copy >/dev/null 2>&1; then wl-copy < "$input_file"
    elif command -v xclip >/dev/null 2>&1; then xclip -selection clipboard < "$input_file"
    else cat "$input_file"; fi
}

copy_to_clipboard "$RESULT_FILE"
IFS='|' read -r _ COUNT HUMAN_SIZE TOKENS < <(grep "^STATS|" "${TMP_DIR}/stats")
printf "\r\033[K" >&2
echo -e "\033[1;32m✔\033[0;32m Copied: \033[1m${COUNT}\033[0;32m files | Size: \033[1m${HUMAN_SIZE}\033[0;32m | Tokens: \033[1m~${TOKENS}\033[0m"

EOF

# Install
$CMD_PREFIX install -m 755 "$TMP_PAYLOAD" "$TARGET_PATH"
rm -f "$TMP_PAYLOAD"

if [ -x "$TARGET_PATH" ]; then
    echo -e "${GREEN}✔ Installed v16.2 (Cross-Platform Edition).${NC}"
else
    echo -e "${RED}✘ Failed.${NC}"
fi
