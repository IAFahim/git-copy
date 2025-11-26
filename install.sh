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
NC='\033[0m'

echo -e "${PURPLE}>> INSTALLING GIT-COPY v16.1 (UNITY EDITION) <<${NC}"

# Permissions Check
CMD_PREFIX=""
if [ ! -w "$INSTALL_DIR" ]; then CMD_PREFIX="sudo"; fi

# Payload Container
TMP_PAYLOAD=$(mktemp)

cat > "$TMP_PAYLOAD" << 'EOF'
#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# ⚡ GIT-COPY | v16.1 | Unity Edition
# ------------------------------------------------------------------------------
set -o nounset
set -o pipefail

# --- CONFIG ---
MAX_SIZE=1048576

# Pass arguments to Perl via ENV
export GIT_COPY_ARGS="$*"

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
    echo -e "${GREEN}✔ Installed v16.1 (Unity Edition).${NC}"
else
    echo -e "${RED}✘ Failed.${NC}"
fi
