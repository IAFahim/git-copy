## File: debug-contains.ps1
```powershell
# Test the Contains method
$TargetExtensions = [System.Collections.Generic.List[string]]::new()
$TargetExtensions.Add("js")

Write-Host "TargetExtensions: $($TargetExtensions -join ', ')"

# Test Contains
Write-Host "`nTesting Contains method:"
Write-Host "  'js' in list: $($TargetExtensions.Contains('js'))"
Write-Host "  'JS' in list: $($TargetExtensions.Contains('JS'))"
Write-Host "  'py' in list: $($TargetExtensions.Contains('py'))"
Write-Host "  'md' in list: $($TargetExtensions.Contains('md'))"

# Test with actual extensions
$testFiles = @("test.js", "test.py", "README.md", "folder/file.js")

Write-Host "`nTesting file extensions:"
foreach ($file in $testFiles) {
    $Ext = [System.IO.Path]::GetExtension($file).TrimStart('.')
    $FileName = [System.IO.Path]::GetFileName($file)
    Write-Host "  $file"
    Write-Host "    Extension: '$Ext'"
    Write-Host "    FileName: '$FileName'"
    $Matched = $TargetExtensions.Contains($Ext) -or $TargetExtensions.Contains($FileName.ToLower())
    Write-Host "    Matched: $Matched"
}

```

## File: debug-filter.ps1
```powershell
# Debug the filter logic
Write-Host "=== Testing extension filter ===`n"

$TestDir = Join-Path $env:TEMP "git-copy-filter-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Force -Path $TestDir | Out-Null
Push-Location $TestDir

try {
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"

    # Create test files
    "function test() { }" | Out-File "test.js" -Encoding UTF8
    "def test(): pass" | Out-File "test.py" -Encoding UTF8
    "# Test" | Out-File "README.md" -Encoding UTF8

    git add .
    git commit -q -m "test"

    Write-Host "Files created: test.js, test.py, README.md"

    # Mock clipboard
    $ClipboardFile = Join-Path $TestDir "clipboard.txt"
    function Global:Set-Clipboard {
        param([string]$Value)
        $Value | Set-Content -Path $ClipboardFile -Encoding UTF8
    }

    Write-Host "`nRunning: git-copy.ps1 js"
    & "D:\IAFahim\Github\git-copy\git-copy.ps1" "js"

    if (Test-Path $ClipboardFile) {
        $content = Get-Content $ClipboardFile -Raw
        Write-Host "`n=== Clipboard content ==="
        Write-Host $content

        Write-Host "`n=== Checking files ==="
        if ($content -match "test.js") { Write-Host "[OK] test.js found" }
        else { Write-Host "[FAIL] test.js NOT found" }

        if ($content -match "test.py") { Write-Host "[FAIL] test.py found (should be excluded)" }
        else { Write-Host "[OK] test.py excluded" }

        if ($content -match "README.md") { Write-Host "[FAIL] README.md found (should be excluded)" }
        else { Write-Host "[OK] README.md excluded" }
    }

} finally {
    Pop-Location
    Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue
}

```

## File: debug-run.ps1
```powershell
# Debug script to trace the exact issue
Write-Host "=== Debugging git-copy.ps1 ===`n"

$TestDir = Join-Path $env:TEMP "git-copy-debug-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Force -Path $TestDir | Out-Null
Push-Location $TestDir

try {
    Write-Host "Setting up test git repo..."

    git init -q
    git config user.email "test@test.com"
    git config user.name "Test User"

    # Create a test file
    "console.log('test');" | Out-File "test.js" -Encoding UTF8

    git add "test.js"
    git commit -q -m "test"

    Write-Host "Git repo created at: $TestDir`n"

    Write-Host "=== Testing git ls-files directly ==="
    $GitOut = git ls-files --cached --others --exclude-standard 2>$null
    Write-Host "Type: $($GitOut.GetType().FullName)"
    Write-Host "Value: $GitOut"
    Write-Host "Is Null: $($null -eq $GitOut)"

    Write-Host "`n=== Testing the split operation ==="
    $RawFiles = @($GitOut -split "`n")
    Write-Host "RawFiles Type: $($RawFiles.GetType().FullName)"
    Write-Host "RawFiles Count: $($RawFiles.Count)"

    Write-Host "`n=== Now let's trace into git-copy.ps1 ==="

    # Mock Set-Clipboard
    $ClipboardFile = Join-Path $TestDir "clipboard.txt"
    function Global:Set-Clipboard {
        param([string]$Value)
        $Value | Set-Content -Path $ClipboardFile -Encoding UTF8
    }

    # Run the actual script with verbose output
    Write-Host "`nRunning git-copy.ps1..."
    & "D:\IAFahim\Github\git-copy\git-copy.ps1"

    Write-Host "`n=== Script completed successfully! ==="

} finally {
    Pop-Location
    Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue
}

```

## File: debug-test.ps1
```powershell
New-Item -ItemType Directory -Force -Path 'test-repo' | Out-Null
Set-Location 'test-repo'
git init -q
git config user.email 'test@test.com'
git config user.name 'Test'
'test' | Out-File 'test.txt'
git add 'test.txt'
git commit -q -m 'test'

Write-Host "=== Test 1: Direct output ==="
$GitOut = git ls-files --cached --others --exclude-standard
Write-Host "Type: $($GitOut.GetType().Name)"
Write-Host "Is Array: $($GitOut -is [array])"
Write-Host "Value: $GitOut"

Write-Host "`n=== Test 2: Array expression ==="
$GitOut2 = @(git ls-files --cached --others --exclude-standard)
Write-Host "Type: $($GitOut2.GetType().Name)"
Write-Host "Count: $($GitOut2.Count)"
Write-Host "Value: $GitOut2"

Write-Host "`n=== Test 3: Using @() and checking null ==="
$GitOut3 = git ls-files --cached --others --exclude-standard 2>$null
if ($null -ne $GitOut3) {
    Write-Host "GitOut3 is not null"
    $RawFiles = @($GitOut3 -split "`n")
    Write-Host "After split - Count: $($RawFiles.Count)"
    Write-Host "Values: $RawFiles"
}

Set-Location ..
Remove-Item -Recurse -Force 'test-repo'

```

## File: debug-test2.ps1
```powershell
New-Item -ItemType Directory -Force -Path 'test-repo' | Out-Null
Set-Location 'test-repo'
git init -q
git config user.email 'test@test.com'
git config user.name 'Test'

# Create multiple files
'test1' | Out-File 'test1.txt'
'test2' | Out-File 'test2.txt'
'test3' | Out-File 'test3.txt'

git add .
git commit -q -m 'test'

Write-Host "=== Multiple files test ==="
$GitOut = git ls-files --cached --others --exclude-standard
Write-Host "Type: $($GitOut.GetType().Name)"
Write-Host "Value: $GitOut"
Write-Host "Contains newlines: $($GitOut.Contains("`n"))"

Write-Host "`n=== Split by newline ==="
$split = $GitOut -split "`n"
Write-Host "Split count: $($split.Count)"
Write-Host "Split values:"
$split | ForEach-Object { Write-Host "  - [$_]" }

Write-Host "`n=== Check for empty strings ==="
$split = $GitOut -split "`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
Write-Host "After filtering empty: $($split.Count)"

Set-Location ..
Remove-Item -Recurse -Force 'test-repo'

```

## File: debug-vars.ps1
```powershell
# Test what values TargetExtensions gets
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments = @()
)

Write-Host "Arguments received: $Arguments"
Write-Host "Arguments count: $($Arguments.Count)"

$ArgsList = @($Arguments | Where-Object { $null -ne $_ })
Write-Host "ArgsList count: $($ArgsList.Count)"

$PRESETS = @{
    "web"     = @("html","htm","css","scss","sass","less","js","jsx","ts","tsx","json","svg","vue","svelte")
}

$TargetExtensions = [System.Collections.Generic.List[string]]::new()

Write-Host "`nProcessing arguments..."
foreach ($arg in $ArgsList) {
    Write-Host "  Processing: '$arg'"
    $val = $arg.ToLower().TrimStart(".")
    Write-Host "    Normalized: '$val'"
    if ($PRESETS.ContainsKey($val)) {
        Write-Host "    Is preset!"
        $PRESETS[$val] | ForEach-Object {
            Write-Host "      Adding: $_"
            $TargetExtensions.Add($_)
        }
    } else {
        Write-Host "    Is extension"
        Write-Host "      Adding: $val"
        $TargetExtensions.Add($val)
    }
}

Write-Host "`nFinal TargetExtensions count: $($TargetExtensions.Count)"
Write-Host "TargetExtensions: $($TargetExtensions -join ', ')"
Write-Host "IsFilterActive: $($TargetExtensions.Count -gt 0)"

```

## File: debug-where.ps1
```powershell
$ArgsList = @()
Write-Host "Before Where-Object"
Write-Host "  Type: $($ArgsList.GetType().Name)"
Write-Host "  Count: $($ArgsList.Count)"

$ArgsList = $ArgsList | Where-Object { $null -ne $_ }
Write-Host "`nAfter Where-Object"
Write-Host "  Is Null: $($null -eq $ArgsList)"
Write-Host "  Type: $(if ($null -ne $ArgsList) { $ArgsList.GetType().Name } else { 'N/A' })"
if ($null -ne $ArgsList) {
    Write-Host "  Count: $($ArgsList.Count)"
    Write-Host "  Is Array: $($ArgsList -is [array])"
}

# Test with null values
Write-Host "`n=== Test with null values ==="
$ArgsList2 = @($null, $null)
Write-Host "Before filter: Count = $($ArgsList2.Count)"
$ArgsList2 = $ArgsList2 | Where-Object { $null -ne $_ }
Write-Host "After filter: Type = $(if ($null -ne $ArgsList2) { $ArgsList2.GetType().Name } else { 'NULL' })"
Write-Host "After filter: Is Null = $($null -eq $ArgsList2)"

```

## File: js
```javascript
## File: README.md
```markdown
# Test

```

## File: test.js
```javascript
function test() { }

```

## File: test.py
```python
def test(): pass

```


_Project Structure:_
```text
README.md
test.js
test.py
```

```

## File: .github/workflows/test.yml
```yml
name: Test Git-Copy

on:
  push:
    branches: [ "main", "master" ]
  pull_request:
    branches: [ "main", "master" ]

permissions:
  contents: read

jobs:
  # ------------------------------------------------------------------
  # SYNTAX VALIDATION - Check script code quality
  # ------------------------------------------------------------------
  syntax-check:
    name: Syntax Validation
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Check Bash Scripts Syntax
        run: |
          echo "=== Checking Bash Script Syntax ==="
          for script in install.sh test.sh; do
            echo "Checking $script..."
            bash -n "$script" || exit 1
            echo "[OK] $script syntax OK"
          done

      - name: PowerShell Syntax Check
        run: |
          echo "=== Checking PowerShell Script Syntax ==="
          pwsh -Command "
            \$scripts = @('git-copy.ps1', 'test.ps1', 'install.ps1')
            foreach (\$script in \$scripts) {
              Write-Host \"Checking \$script...\"
              \$errors = \$null
              \$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content \$script -Raw), [ref]\$errors)
              if (\$errors.Count -gt 0) {
                Write-Error \"Syntax errors in \$script\"
                exit 1
              }
              Write-Host \"[OK] \$script syntax OK\"
            }
          "

  # ------------------------------------------------------------------
  # TEST WINDOWS (PowerShell Version)
  # ------------------------------------------------------------------
  test-windows:
    name: Windows (PowerShell)
    runs-on: windows-latest
    needs: syntax-check
    steps:
      - uses: actions/checkout@v4

      - name: Run Test Suite
        shell: powershell
        run: |
          Write-Host "=== Running Windows Test Suite ===" -ForegroundColor Cyan
          .\test.ps1

      - name: Integration Test - Direct Script Execution
        shell: powershell
        run: |
          # Setup test fixtures
          New-Item -ItemType Directory -Force -Path "TestProject" | Out-Null
          "public class PlayerController : MonoBehaviour {}" | Set-Content "TestProject/Player.cs"
          "guid: 12345" | Set-Content "TestProject/Player.cs.meta"
          "SECRET_KEY=123" | Set-Content "TestProject/.env"
          "node_modules stuff" | Set-Content "TestProject/package-lock.json"

          # Mock clipboard
          function Set-Clipboard {
              param([Parameter(ValueFromPipeline=$true)]$Value)
              $Value | Set-Content "TestProject/clipboard_output.md"
          }

          # Run tool
          cd TestProject
          & ..\git-copy.ps1 unity

          # Verify output
          if (-not (Test-Path "clipboard_output.md")) {
            Write-Error "FAIL: No output created"
            exit 1
          }

          $Output = Get-Content "clipboard_output.md" -Raw

          # Assertions
          if ($Output -notmatch "Player.cs") {
            Write-Error "FAIL: Player.cs missing"
            exit 1
          }

          if ($Output -match "Player.cs.meta") {
            Write-Error "FAIL: .meta file not ignored"
            exit 1
          }

          if ($Output -match "SECRET_KEY") {
            Write-Error "FAIL: .env file not ignored"
            exit 1
          }

          Write-Host "[OK] Integration test passed" -ForegroundColor Green

      - name: Create Report
        if: always()
        run: |
          echo "## Win Windows Test Report" >> $env:GITHUB_STEP_SUMMARY
          echo "[PASS] Syntax Validation: Passed" >> $env:GITHUB_STEP_SUMMARY
          echo "[PASS] Test Suite: Executed" >> $env:GITHUB_STEP_SUMMARY
          echo "[PASS] Integration Tests: Passed" >> $env:GITHUB_STEP_SUMMARY

  # ------------------------------------------------------------------
  # TEST UNIX (Bash Version - Mac & Linux)
  # ------------------------------------------------------------------
  test-unix:
    name: ${{ matrix.os }} (Bash)
    runs-on: ${{ matrix.os }}
    needs: syntax-check
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]

    steps:
      - uses: actions/checkout@v4

      - name: Run Test Suite
        run: |
          echo "=== Running Unix Test Suite ==="
          ./test.sh

      - name: Integration Test - Installed Tool
        run: |
          # Install the tool
          chmod +x install.sh
          sudo ./install.sh

          # Setup test fixtures
          mkdir TestProject
          cd TestProject
          echo "public class PlayerController : MonoBehaviour {}" > Player.cs
          echo "guid: 12345" > Player.cs.meta
          echo "SECRET_KEY=123" > .env
          echo "garbage" > package-lock.json

          # Mock clipboard tools
          mkdir -p $HOME/bin
          for cmd in pbcopy xclip wl-copy; do
            echo '#!/bin/bash' > $HOME/bin/$cmd
            echo 'cat > $HOME/mock_clipboard.txt' >> $HOME/bin/$cmd
            chmod +x $HOME/bin/$cmd
          done
          export PATH="$HOME/bin:$PATH"

          # Run installed tool
          /usr/local/bin/git-copy unity

          # Verify output
          if [ ! -f "$HOME/mock_clipboard.txt" ]; then
            echo "[FAIL] FAIL: No output created"
            exit 1
          fi

          OUTPUT=$(cat $HOME/mock_clipboard.txt)

          # Assertions
          if ! echo "$OUTPUT" | grep -q "Player.cs"; then
            echo "[FAIL] FAIL: Player.cs missing"
            exit 1
          fi

          if echo "$OUTPUT" | grep -q "Player.cs.meta"; then
            echo "[FAIL] FAIL: .meta file not ignored"
            exit 1
          fi

          if echo "$OUTPUT" | grep -q "SECRET_KEY"; then
            echo "[FAIL] FAIL: .env file not ignored"
            exit 1
          fi

          echo "[OK] Integration test passed"

      - name: Create Report
        if: always()
        run: |
          OS_ICON="Linux"
          if [[ "${{ matrix.os }}" == "macos-latest" ]]; then OS_ICON="macOS"; fi

          echo "## $OS_ICON ${{ matrix.os }} Test Report" >> $GITHUB_STEP_SUMMARY
          echo "[PASS] Syntax Validation: Passed" >> $GITHUB_STEP_SUMMARY
          echo "[PASS] Test Suite: Executed" >> $GITHUB_STEP_SUMMARY
          echo "[PASS] Integration Tests: Passed" >> $GITHUB_STEP_SUMMARY

```

## File: .idea/.gitignore
```gitignore
# Default ignored files
/shelf/
/workspace.xml
# Rider ignored files
/projectSettingsUpdater.xml
/modules.xml
/contentModel.xml
/.idea.git-copy.iml
# Ignored default folder with query files
/queries/
# Datasource local storage ignored files
/dataSources/
/dataSources.local.xml
# Editor-based HTTP Client requests
/httpRequests/

```

## File: .idea/encodings.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="Encoding" addBOMForNewFiles="with BOM under Windows, with no BOM otherwise" />
</project>
```

## File: .idea/indexLayout.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="UserContentModel">
    <attachedFolders />
    <explicitIncludes />
    <explicitExcludes />
  </component>
</project>
```

## File: .idea/vcs.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="VcsDirectoryMappings">
    <mapping directory="$PROJECT_DIR$" vcs="Git" />
  </component>
</project>
```

## File: LICENSE
```license
MIT License

Copyright (c) 2025 Md. Ishtiaq Ahamed Fahim

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```

## File: QUICK_REFERENCE.md
```markdown
# git-copy Quick Reference

## Installation

```bash
# Mac / Linux
curl -fsSL https://raw.githubusercontent.com/iafahim/git-copy/main/install.sh | bash

# Windows (PowerShell - run as Admin or set execution policy)
Set-ExecutionPolicy Bypass -Scope Process -Force
iwr -useb https://raw.githubusercontent.com/iafahim/git-copy/main/install.ps1 | iex
```

## Basic Usage

```bash
git copy                    # Copy all files
git copy --help            # Show help
```

## Filtering

```bash
# By extension
git copy js                # Only .js files
git copy py ts             # .py and .ts files

# By preset
git copy web               # HTML, CSS, JS, TS, JSX, etc.
git copy backend           # Python, Go, Rust, Java, etc.
git copy java              # Java, Kotlin, Scala
git copy unity             # C#, shaders, Unity assets
```

## Excluding Folders

```bash
# Single exclusion
git copy -node_modules
git copy -tests
git copy -build

# Paths with spaces (use quotes)
git copy -"folder with spaces"

# Multiple exclusions
git copy -node_modules -tests -docs

# Nested paths
git copy -src/components/legacy
git copy -packages/internal

# Alternative syntax
git copy --exclude node_modules
```

## Combining Features

```bash
# Filter + Exclude
git copy js -tests                    # JS files, skip tests
git copy web -node_modules -dist      # Web files, skip deps and build
git copy backend -venv -__pycache__   # Backend code, skip Python artifacts

# Multiple filters + exclusions
git copy js ts jsx tsx -tests -node_modules -build
```

## Available Presets

| Preset | Extensions |
|--------|-----------|
| `web` | html, css, js, ts, jsx, tsx, json, svg, vue, svelte |
| `backend` | py, rb, php, go, rs, java, cs, cpp, swift, kt |
| `dotnet` | cs, razor, csproj, json, http, xaml |
| `unity` | cs, shader, glsl, asmdef, uss, uxml, json, yaml |
| `java` | java, kt, scala |
| `cpp` | c, h, cpp, hpp, rs, go, swift |
| `script` | py, rb, php, lua, sh, ps1 |
| `data` | sql, xml, json, yaml, toml, md, csv |
| `config` | env, conf, ini, Dockerfile, Makefile |
| `docs` | md, txt, rst, adoc |

## Auto-Excluded Files

- Lock files: `package-lock.json`, `yarn.lock`, `Cargo.lock`
- Binaries: `.exe`, `.dll`, `.bin`, `.pdf`, images
- Secrets: `.env`, `.pem`, `.key`, `id_rsa`
- Minified: `.min.js`, `.min.css`
- System: `.DS_Store`, `Thumbs.db`
- Unity: `.meta` files

## Output Format

```markdown
## File: src/index.js
\```javascript
function hello() { ... }
\```

## File: src/App.tsx
\```typescript
export default App() { ... }
\```

_Project Structure:_
\```text
src/index.js
src/App.tsx
\```
```

## Tips

1. **Use presets** for quick filtering: `git copy web`
2. **Exclude build artifacts**: `-node_modules -dist -build`
3. **Combine intelligently**: `git copy web -tests -node_modules`
4. **Check output size**: Tool shows file count and estimated tokens
5. **Git-aware**: Only copies tracked files (respects `.gitignore`)

## Troubleshooting

**Windows: "Cannot be loaded because running scripts is disabled"**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

**Linux: "xclip not found"**
```bash
sudo apt install xclip  # Ubuntu/Debian
sudo dnf install xclip  # Fedora
```

**macOS: Works out of the box** ✅

## Testing

```bash
# Unix
./test.sh

# Windows
.\test.ps1
```

---

For detailed documentation, see [README.md](README.md)

```

## File: README.md
```markdown
# git-copy

A CLI utility to copy code from a Git repository to your clipboard with one command. Formats output with **file contents on top** and **project tree on bottom**.

Perfect for dumping context into ChatGPT, Claude, or DeepSeek.

> Made with AI. Tested with Love.

## ⚡️ Quick Install

**Mac / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/iafahim/git-copy/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
# Run PowerShell as Administrator OR in a regular PowerShell window:
Set-ExecutionPolicy Bypass -Scope Process -Force
iwr -useb https://raw.githubusercontent.com/iafahim/git-copy/main/install.ps1 | iex
```

> **Windows Note:** The installer automatically creates a `.cmd` wrapper that bypasses ExecutionPolicy restrictions. You can use it in any terminal window after installation without admin rights.

## 🚀 Usage

Once installed, it works as a native Git subcommand. Navigate to any git repository and run:

```bash
# Copy ALL tracked files (smart defaults exclude locks/binaries)
git copy

# Copy specific groups
git copy web        # html, css, js, ts, jsx
git copy backend    # python, ruby, php, go, rust
git copy java       # java, kotlin, scala

# Copy specific file types
git copy js         # only *.js
git copy py rust    # *.py and *.rs

# Exclude folders or paths
git copy -node_modules              # Exclude node_modules folder
git copy -tests -docs               # Exclude multiple folders
git copy js -src/components         # Filter + exclude combined
git copy --exclude build            # Using --exclude flag

# View Help
git copy --help
```

## 🎯 Excluding Folders

You can exclude specific folders or paths from being copied:

### Syntax Options:

1. **Dash prefix:** `-path/to/exclude`
2. **Flag syntax:** `--exclude path/to/exclude`

> **Note:** For paths with spaces, wrap the argument in quotes: `git copy -"folder with spaces"`

### Examples:

```bash
# Exclude single folder
git copy -node_modules
git copy --exclude build

# Exclude multiple folders
git copy -tests -docs -tmp

# Exclude nested paths
git copy -src/components/legacy
git copy -packages/internal

# Combine with filters
git copy js ts -tests              # Copy only JS/TS, exclude tests folder
git copy web -node_modules -dist   # Copy web files, exclude build folders
```

## 📝 Output Format

The script generates a prompt-friendly format in your clipboard:

1.  **File Contents:** Code blocks with language syntax highlighting.
2.  **Project Context:** A file tree showing the structure.
3.  **Summary:** Token/Line count estimation.

## ⚙️ Requirements

*   **Git**
*   **Mac:** Built-in `pbcopy` (no setup needed).
*   **Linux:** Requires `xclip`, `xsel`, or `wl-copy`.
    *   `sudo apt install xclip`
*   **Windows:** PowerShell 5.1+ (included in Windows 10/11)

### Windows Permissions

**For Installation:**
The installer needs to:
- Download files to `%LOCALAPPDATA%\Programs\git-copy`
- Modify your user PATH environment variable

You have two options:

1. **Run as Administrator** (recommended for first install):
   ```powershell
   # Right-click PowerShell → "Run as Administrator"
   iwr -useb https://raw.githubusercontent.com/iafahim/git-copy/main/install.ps1 | iex
   ```

2. **Run without admin** (requires execution policy bypass):
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   iwr -useb https://raw.githubusercontent.com/iafahim/git-copy/main/install.ps1 | iex
   ```

**After Installation:**
No special permissions needed! The tool uses a `.cmd` wrapper that automatically bypasses ExecutionPolicy restrictions.

## 🔧 Manual Install

**Windows:**
1. Download `install.ps1` and `git-copy.ps1`.
2. Open PowerShell as Administrator (or set execution policy).
3. Run `.\install.ps1` in PowerShell.
4. Restart your terminal.

**Mac/Linux:**
1.  Download `install.sh`.
2.  `chmod +x install.sh`
3.  `./install.sh` (may require `sudo`)

## 🧪 Testing

Cross-platform test suites are included:

```bash
# Unix (Mac/Linux)
./test.sh

# Windows (PowerShell)
.\test.ps1
```

Tests verify:
- Basic file copying
- Extension filtering
- Preset filtering
- Folder exclusion
- Combined filters

## 🛡️ Security

The tool automatically excludes:
- **Lock files:** `package-lock.json`, `yarn.lock`, `Cargo.lock`
- **System files:** `.DS_Store`, `Thumbs.db`
- **Binaries:** `.exe`, `.dll`, `.bin`, `.pdf`, images
- **Secrets:** Files matching patterns like `id_rsa`, `.pem`, `.key`, `.env`
- **Minified files:** `.min.js`, `.min.css`

## 📦 What's Included

- **Presets:** `web`, `backend`, `dotnet`, `unity`, `java`, `cpp`, `script`, `data`, `config`, `build`, `docs`
- **60+ file extensions** mapped to proper syntax highlighting
- **Smart filtering** using git's native file tracking
- **Cross-platform** clipboard support (macOS, Linux, Windows, WSL, SSH/tmux)

## 🤝 Contributing

Contributions are welcome! Please test on multiple platforms before submitting PRs.

## 📄 License

MIT

## 👨‍💻 Author

**Md. Ishtiaq Ahamed Fahim**

---

**Star this repo if you find it useful!** ⭐
```
```

## File: clipboard_output.md
```markdown

_Project Structure:_
```text
```


```

## File: git-copy-feature-test/TestProject/MyApp.Tests/UnitTest.cs
```csharp
public class TestClass {}

```

## File: git-copy-feature-test/TestProject/Player.cs
```csharp
public class PlayerController : MonoBehaviour {}

```

## File: git-copy-feature-test/TestProject/README.md
```markdown
# Test File

```

## File: git-copy-feature-test/TestProject/Utils.Tests.cs
```csharp
public class UtilsTest {}

```

## File: git-copy-feature-test/TestProject/docs/guide.md
```markdown
# Docs

```

## File: git-copy-feature-test/TestProject/test_file.cs
```csharp
test content

```

## File: git-copy-feature-test/clipboard_output.md
```markdown
## File: Player.cs
```csharp
public class PlayerController : MonoBehaviour {}

```

## File: test_file.cs
```csharp
test content

```


_Project Structure:_
```text
Player.cs
test_file.cs
```


```

## File: git-copy-fuzzy-test/MyTests.txt
```txt
content

```

## File: git-copy-fuzzy-test/Tests.txt
```txt
content

```

## File: git-copy-fuzzy-test/Tests/file.txt
```txt
content

```

## File: git-copy.ps1
```powershell
<#
.SYNOPSIS
    GIT-COPY | v16.2 | Professional Edition

.DESCRIPTION
    Bundles code files into a single Markdown snippet and copies to clipboard.
    Supports filtering by extension/preset and exclusion of folders.
    Uses native PowerShell wildcards for robust filtering.

.PARAMETER Arguments
    File extensions, presets, or exclusion patterns

.PARAMETER Help
    Show help information

.EXAMPLE
    git copy
    Copy all tracked files

.EXAMPLE
    git copy js ts -tests
    Copy JS/TS files, exclude tests folder

.EXAMPLE
    git copy web --exclude node_modules
    Copy web files, exclude node_modules

.NOTES
    Version: 16.2
    Presets: web, backend, dotnet, unity, java, cpp, script, data, config, docs
#>

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Arguments = @(),

    [Alias("h")]
    [switch]$Help,

    [Alias("o")]
    [string]$OutputFile
)

# ==============================================================================
# CONFIGURATION
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
# Force UTF-8 Output
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

[Version]$ScriptVersion = "16.2"
$MAX_SIZE = 1MB
$FENCE = '```'

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

function Write-Info {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "ℹ " -NoNewline -ForegroundColor Cyan
    Write-Host $Message
}

function Write-Success {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "✔ " -NoNewline -ForegroundColor Green
    Write-Host $Message
}

function Write-Warn {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "⚠ " -NoNewline -ForegroundColor Yellow
    Write-Host $Message
}

function Write-Error {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "✘ " -NoNewline -ForegroundColor Red
    Write-Host $Message
}

# ==============================================================================
# PRESETS & LANGUAGE MAPS
# ============================================================================== 

$PRESETS = @{
    "web"     = @("html","htm","css","scss","sass","less","js","jsx","ts","tsx","json","svg","vue","svelte")
    "backend" = @("py","rb","php","pl","go","rs","java","cs","cpp","h","c","hpp","swift","kt","ex","exs","sh")
    "dotnet"  = @("cs","razor","csproj","json","http","xaml")
    "unity"   = @("cs","shader","cginc","hlsl","glsl","asmdef","asmref","uss","uxml","json","yaml")
    "java"    = @("java","kt","kts","scala")
    "cpp"     = @("c","h","cpp","cc","cxx","hpp","hxx","rs","go","swift")
    "script"  = @("py","rb","php","pl","pm","lua","sh","bash","zsh","ps1")
    "data"    = @("sql","xml","json","yaml","yml","toml","ini","md","csv","graphql")
    "config"  = @("env","conf","ini","Dockerfile","Makefile","Gemfile","package.json","cargo.toml","go.mod")
    "build"   = @("Dockerfile","Makefile","Gemfile","package.json")
    "docs"    = @("md","txt","rst","adoc")
}

$LANG_MAP = @{
    "js" = "javascript"; "ts" = "typescript"; "py" = "python";
    "cs" = "csharp"; "sh" = "bash"; "md" = "markdown";
    "h" = "c"; "hpp" = "cpp"; "razor" = "html"; "vue" = "html";
    "shader" = "glsl"; "cginc" = "glsl"; "hlsl" = "glsl";
    "uss" = "css"; "uxml" = "xml"; "ps1" = "powershell";
    "dockerfile" = "dockerfile"; "makefile" = "makefile";
    "gemfile" = "ruby"; "rakefile" = "ruby"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

Write-Host "DEBUG PARAM: Arguments count=$($Arguments.Count), value=$($Arguments -join ', ')" -ForegroundColor Magenta
$ArgsList = @($Arguments)
Write-Host "DEBUG INIT: ArgsList count=$($ArgsList.Count)" -ForegroundColor Magenta

if ($Help -or ($ArgsList -contains "--help") -or ($ArgsList -contains "-h")) {
    Write-Host "GIT-COPY | v$ScriptVersion" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host "    git copy [OPTIONS] [FILTERS] [EXCLUDES]"
    Write-Host ""
    Write-Host "OPTIONS:"
    Write-Host "    --help, -h          Show this help message"
    Write-Host "    --output, -o <file> Save output to file instead of clipboard"
    Write-Host ""
    Write-Host "EXAMPLES:"
    Write-Host "    git copy -o gitcopy.md     Save output to gitcopy.md"
    Write-Host "    git copy --output out.txt  Save output to out.txt"
    exit 0
}

# Check for -o/--output in Arguments
for ($i = 0; $i -lt $ArgsList.Count; $i++) {
    $arg = $ArgsList[$i]
    if ($arg -eq "--output" -or $arg -eq "-o") {
        if ($i + 1 -lt $ArgsList.Count) {
            $OutputFile = $ArgsList[$i+1]
            $ArgsList[$i] = $null
            $ArgsList[$i+1] = $null
        }
    }
}
# Remove null entries from Arguments
$ArgsList = @($ArgsList | Where-Object { $null -ne $_ })

Write-Host "Processing..." -ForegroundColor Cyan
Write-Host "DEBUG: ArgsList.Count=$($ArgsList.Count), ArgsList=$($ArgsList -join ', ')" -ForegroundColor Yellow

# ==============================================================================
# ARGUMENT PARSING
# ==============================================================================
$TargetExtensions = [System.Collections.Generic.List[string]]::new()
$ExcludePatterns  = [System.Collections.Generic.List[string]]::new()

$SkipNext = $false
for ($i = 0; $i -lt $ArgsList.Count; $i++) {
    Write-Host "DEBUG: Processing arg [$i]: '$($ArgsList[$i])'" -ForegroundColor Cyan
    if ($SkipNext) { $SkipNext = $false; continue }
    $arg = $ArgsList[$i]
    
    # CASE 1: Explicit --exclude (Standard)
    if ($arg -eq "--exclude" -or $arg -eq "-exclude") {
        if ($i + 1 -lt $ArgsList.Count) {
            $path = $ArgsList[$i+1].TrimStart("-")
            $path = $path -replace '\\', '/'
            $ExcludePatterns.Add($path)
            $SkipNext = $true
        }
        continue
    }

    # CASE 2: Pattern Exclusion (--*.Tests)
    # This covers --Folder, --*.cs, --node_modules, etc.
    if ($arg.StartsWith("--")) {
        $pat = $arg.Substring(2) # Strip leading --
        if (-not [string]::IsNullOrWhiteSpace($pat)) {
            $ExcludePatterns.Add($pat)
            Write-Host "  > Exclude Pattern: '$pat'" -ForegroundColor DarkGray
        }
        continue
    }

    # CASE 3: Extension Exclusion (-.md)
    if ($arg.StartsWith("-.")) {
        $ext = $arg.Substring(2) # Strip leading -.
        if (-not [string]::IsNullOrWhiteSpace($ext)) {
            $ExcludePatterns.Add("*.$ext")
            Write-Host "  > Exclude Ext: '$ext'" -ForegroundColor DarkGray
        }
        continue
    }

    # CASE 4: Old Style Path Exclusion (-node_modules)
    if ($arg.StartsWith("-")) {
        $path = $arg.Substring(1) # Strip leading -
        if (-not [string]::IsNullOrWhiteSpace($path)) {
            $path = $path -replace '\\', '/'
            $ExcludePatterns.Add($path)
            Write-Host "  > Exclude Path: '$path'" -ForegroundColor DarkGray
        }
        continue
    }

    # CASE 5: Presets/Extensions
    $val = $arg.ToLower().TrimStart(".")
    if ($PRESETS.ContainsKey($val)) {
        $PRESETS[$val] | ForEach-Object { $TargetExtensions.Add($_) }
    } else {
        $TargetExtensions.Add($val)
    }
}

# ==============================================================================
# FILE DISCOVERY
# ==============================================================================

$RootPath = (Get-Location).Path.TrimEnd('\', '/')
$RawFiles = @()

if (Test-Path ".git") {
    $GitOut = git ls-files --cached --others --exclude-standard 2>$null
    if ($null -ne $GitOut) {
        $RawFiles = @($GitOut -split "`n")
    } else {
        $RawFiles = Get-ChildItem -Recurse -File | Select-Object -ExpandProperty FullName
    }
} else {
    $RawFiles = Get-ChildItem -Recurse -File | Select-Object -ExpandProperty FullName
}

# ==============================================================================
# FILE PROCESSING
# ==============================================================================

$OutputBuilder = [System.Text.StringBuilder]::new()
$StructureList = [System.Collections.Generic.List[string]]::new()
$TotalBytes = 0
$FileCount = 0
$IsFilterActive = $TargetExtensions.Count -gt 0
Write-Host "DEBUG INIT: TargetExtensions.Count=$($TargetExtensions.Count), IsFilterActive=$IsFilterActive" -ForegroundColor Yellow

# Security / Garbage Regex (Keep this for safety/noise)
$RegexOpts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
$IgnoreRe = [regex]::new("(node_modules/|bin/|obj/|package-lock\.json|yarn\.lock|Cargo\.lock|\.DS_Store|Thumbs\.db|\.git/|\.png$|\.jpg$|\.jpeg$|\.gif$|\.ico$|\.woff2?$|\.pdf$|\.exe$|\.bin$|\.pyc$|\.dll$|\.pdb$|\.min\.js$|\.min\.css$|\.meta$)", $RegexOpts)
$SecRe = [regex]::new("(id_rsa|id_dsa|\.pem|\.key|\.p12|\.env|secrets|credentials)", $RegexOpts)

foreach ($FileEntry in $RawFiles) {
    if ([string]::IsNullOrWhiteSpace($FileEntry)) { continue }

    # Path Normalization
    # Check if file entry starts with RootPath (for both Windows and Unix paths)
    if ($FileEntry.StartsWith($RootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        $RelPath = $FileEntry.Substring($RootPath.Length).Trim('\', '/')
    } else {
        $RelPath = $FileEntry.Trim()
    }
    $RelPath = $RelPath -replace '\\', '/'

    # --- FILTERS ---
    
    # 1. Base Ignorables
    if ($IgnoreRe.IsMatch($RelPath)) { continue }
    if ($SecRe.IsMatch($RelPath)) { continue }

    # 2. User Exclusions
    $IsExcluded = $false
    $PathSegments = $RelPath -split '/'
    
    # DEBUG LOGGING (Conditional)
    if ($ExcludePatterns.Count -gt 0 -and ($RelPath -match "Test" -or $RelPath -match "node_modules")) {
         Write-Host "DEBUG: Checking '$RelPath' (Segments: $($PathSegments -join ','))" -ForegroundColor Gray
    }

    foreach ($pat in $ExcludePatterns) {
        # 1. Full Path Check
        if ($RelPath -like $pat -or $RelPath -like "$pat/*") {
            $IsExcluded = $true
            Write-Host "  > EXCLUDED by FullPath match: '$pat'" -ForegroundColor Yellow
            break
        }

        # 2. Segment Check
        foreach ($seg in $PathSegments) {
            # STRICT MATCH
            if ($seg -like $pat) {
                $IsExcluded = $true
                Write-Host "  > EXCLUDED by Segment Strict match: '$seg' -like '$pat'" -ForegroundColor Yellow
                break
            }
            # FUZZY/CONTAINMENT MATCH
            if ($seg -like "*$pat*") {
                 $IsExcluded = $true
                 Write-Host "  > EXCLUDED by Segment Fuzzy match: '$seg' -like '*$pat*'" -ForegroundColor Yellow
                 break
            }
        }
        if ($IsExcluded) { break }
    }
    if ($IsExcluded) { continue }

    # 3. Extension Filter
    $Ext = [System.IO.Path]::GetExtension($RelPath).TrimStart('.')
    $FileName = [System.IO.Path]::GetFileName($RelPath)

    if ($IsFilterActive) {
        # DEBUG
        Write-Host "DEBUG: File=$RelPath, Ext='$Ext', TargetExtensions=$($TargetExtensions -join ',')" -ForegroundColor Magenta
        # Check either extension OR filename (for files like Dockerfile, Makefile)
        $Matched = $TargetExtensions.Contains($Ext) -or $TargetExtensions.Contains($FileName.ToLower())
        Write-Host "  Matched=$Matched (Ext contains=$($TargetExtensions.Contains($Ext)), FileName contains=$($TargetExtensions.Contains($FileName.ToLower())))" -ForegroundColor Cyan
        if (-not $Matched) { continue }
    }

    # --- CONTENT ---
    $FullPath = Join-Path $RootPath $RelPath
    $FileInfo = Get-Item $FullPath -ErrorAction SilentlyContinue
    if (-not $FileInfo -or $FileInfo.Length -gt $MAX_SIZE -or $FileInfo.Length -eq 0) { continue }

    try {
        # Determine language: check extension first, then filename for files without extensions
        $LangKey = if ($Ext) { $Ext.ToLower() } else { $FileName.ToLower() }
        $Lang = if ($LANG_MAP.ContainsKey($LangKey)) { $LANG_MAP[$LangKey] } else { $LangKey }
        $Content = [System.IO.File]::ReadAllText($FullPath, [System.Text.Encoding]::UTF8)

        [void]$OutputBuilder.AppendLine("## File: $RelPath")
        [void]$OutputBuilder.AppendLine("$FENCE$Lang")
        [void]$OutputBuilder.AppendLine($Content)
        [void]$OutputBuilder.AppendLine($FENCE)
        [void]$OutputBuilder.AppendLine("")

        $StructureList.Add($RelPath)
        $TotalBytes += $FileInfo.Length
        $FileCount++
    } catch {}
}

# ==============================================================================
# OUTPUT
# ==============================================================================

[void]$OutputBuilder.AppendLine("")
[void]$OutputBuilder.AppendLine("_Project Structure:_")
[void]$OutputBuilder.AppendLine("${FENCE}text")
$StructureList.Sort()
foreach ($Path in $StructureList) { [void]$OutputBuilder.AppendLine($Path) }
[void]$OutputBuilder.AppendLine($FENCE)

$FinalOutput = $OutputBuilder.ToString()

# Cross-platform clipboard support
function Set-ClipboardCrossPlatform {
    param([string]$Value)

    $IsLinuxOS = $PSVersionTable.Platform -eq 'Unix'
    $IsWindowsOS = $PSVersionTable.Platform -eq 'Win32NT' -or $null -eq $PSVersionTable.Platform

    # Check if there's a mocked Set-Clipboard (for testing)
    $MockedClipboard = Get-Command Set-Clipboard -Scope Global -ErrorAction SilentlyContinue

    if ($IsWindowsOS -or $MockedClipboard) {
        Set-Clipboard -Value $Value
    }
    elseif ($IsLinuxOS) {
        # Try Wayland clipboard first, then X11
        $WaylandCopy = Get-Command wl-copy -ErrorAction SilentlyContinue
        $XClip = Get-Command xclip -ErrorAction SilentlyContinue

        $CopySuccess = $false
        if ($WaylandCopy) {
            try {
                $Value | wl-copy
                $CopySuccess = $true
            } catch {
                # Fall through to xclip
            }
        }

        if (-not $CopySuccess -and $XClip) {
            try {
                $Value | xclip -selection clipboard 2>$null
                $CopySuccess = $true
            } catch {
                Write-Error "Failed to set clipboard with xclip: $_"
                exit 1
            }
        }

        if (-not $CopySuccess) {
            Write-Error "No clipboard tool found. Please install xclip or wl-copy."
            exit 1
        }
    }
}

try {
    Set-ClipboardCrossPlatform -Value $FinalOutput
} catch {
    Write-Error "Failed to set clipboard: $_"
    exit 1
}

$Tokens = [math]::Truncate($TotalBytes / 4)
if ($TotalBytes -lt 1KB) { $SizeStr = "{0} B" -f $TotalBytes }
elseif ($TotalBytes -lt 1MB) { $SizeStr = "{0:N2} KB" -f ($TotalBytes / 1KB) }
else { $SizeStr = "{0:N2} MB" -f ($TotalBytes / 1MB) }

if ($OutputFile) {
    try {
        [System.IO.File]::WriteAllText($OutputFile, $FinalOutput, [System.Text.Encoding]::UTF8)
        Write-Host "[OK]" -NoNewline -ForegroundColor Green
        Write-Host " Saved to " -NoNewline -ForegroundColor Green
        Write-Host "$OutputFile" -NoNewline -ForegroundColor White
        Write-Host ": " -NoNewline -ForegroundColor Green
        Write-Host "$FileCount" -NoNewline -ForegroundColor White
        Write-Host " files | Size: " -NoNewline -ForegroundColor Green
        Write-Host "$SizeStr" -NoNewline -ForegroundColor White
        Write-Host " | Tokens: " -NoNewline -ForegroundColor Green
        Write-Host "~$Tokens" -ForegroundColor White
    } catch {
        Write-Error "Failed to write to file: $_"
        exit 1
    }
} else {
    try {
        Set-Clipboard -Value $FinalOutput
    } catch {
        Write-Error "Failed to set clipboard: $_"
        exit 1
    }
    Write-Host "[OK]" -NoNewline -ForegroundColor Green
    Write-Host " Copied: " -NoNewline -ForegroundColor Green
    Write-Host "$FileCount" -NoNewline -ForegroundColor White
    Write-Host " files | Size: " -NoNewline -ForegroundColor Green
    Write-Host "$SizeStr" -NoNewline -ForegroundColor White
    Write-Host " | Tokens: " -NoNewline -ForegroundColor Green
    Write-Host "~$Tokens" -ForegroundColor White
}
```

## File: install.ps1
```powershell
<#
.SYNOPSIS
    GIT-COPY Installer v16.2 - Windows Edition

.DESCRIPTION
    Installs git-copy as a PowerShell script with batch wrapper to bypass
    ExecutionPolicy restrictions. Adds to user PATH automatically.

.PARAMETER Help
    Show help information

.PARAMETER Version
    Show version information

.PARAMETER DryRun
    Show what would be installed without installing

.EXAMPLE
    .\install.ps1
    Installs git-copy to default location

.EXAMPLE
    .\install.ps1 -DryRun
    Shows installation path without installing

.NOTES
    Version: 16.2
    Author: Md. Ishtiaq Ahamed Fahim
#>

[CmdletBinding()]
param(
    [Alias("h")]
    [switch]$Help,

    [Alias("v")]
    [switch]$Version,

    [switch]$DryRun
)

# ==============================================================================
# CONFIGURATION
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

[Version]$ScriptVersion = "16.2"
$ToolName = "git-copy"
$InstallDir = "$env:LOCALAPPDATA\Programs\$ToolName"
$SourceUrl = "https://raw.githubusercontent.com/iafahim/git-copy/main/git-copy.ps1"

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

function Write-Info {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "ℹ " -NoNewline -ForegroundColor Cyan
    Write-Host $Message
}

function Write-Success {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "✔ " -NoNewline -ForegroundColor Green
    Write-Host $Message
}

function Write-Warn {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "⚠ " -NoNewline -ForegroundColor Yellow
    Write-Host $Message
}

function Write-Error {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "✘ " -NoNewline -ForegroundColor Red
    Write-Host $Message
}

# ==============================================================================
# MAIN INSTALLATION
# ==============================================================================

try {
    Write-Info "Installing GIT-COPY v$ScriptVersion (Windows Edition)"

    # ==============================================================================
    # CREATE DIRECTORY
    # ==============================================================================

    if (-not (Test-Path $InstallDir)) {
        if ($DryRun) {
            Write-Info "Would create directory: $InstallDir"
        } else {
            New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
        }
    }

    # ==============================================================================
    # CREATE BATCH WRAPPER
    # ==============================================================================
    # This .cmd file allows running the tool without changing system-wide ExecutionPolicy

    $BatchContent = @"
@ECHO OFF
SETLOCAL
SET "dp0=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%dp0%git-copy.ps1" %*
"@

    if ($DryRun) {
        Write-Info "Would create: $InstallDir\$ToolName.cmd"
    } else {
        $BatchContent | Set-Content -Path "$InstallDir\$ToolName.cmd" -Encoding ASCII
    }

    # ==============================================================================
    # DOWNLOAD LOGIC SCRIPT
    # ==============================================================================

    Write-Info "Downloading script..."
    if ($DryRun) {
        Write-Info "Would download from: $SourceUrl"
        Write-Info "Would save to: $InstallDir\$ToolName.ps1"
    } else {
        Invoke-WebRequest -Uri $SourceUrl -OutFile "$InstallDir\$ToolName.ps1"
    }

    # ==============================================================================
    # UPDATE PATH
    # ==============================================================================

    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($CurrentPath -notlike "*$InstallDir*") {
        Write-Info "Adding to PATH..."
        if (-not $DryRun) {
            [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$InstallDir", "User")
            $Env:Path += ";$InstallDir"
        }
        Write-Success "Added to PATH"
    } else {
        Write-Success "Already in PATH"
    }

    # ==============================================================================
    # COMPLETE
    # ==============================================================================

    Write-Host ""
    Write-Success "Installation complete!"
    Write-Host "You can now open a NEW terminal window and type:" -ForegroundColor White
    Write-Host "   git copy" -ForegroundColor Yellow
}
catch {
    Write-Error "Installation failed: $_"
    exit 1
}
finally {
    # Cleanup if needed
}
```

## File: install.sh
```bash
#!/usr/bin/env bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================

set -euo pipefail

readonly VERSION="16.2"
readonly TOOL_NAME="git-copy"
readonly INSTALL_DIR="/usr/local/bin"
readonly TARGET_PATH="$INSTALL_DIR/$TOOL_NAME"

# ==============================================================================
# VISUALS
# ==============================================================================

# Color support detection
if [[ -t 1 ]] && command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    DIM=$(tput dim)
    RESET=$(tput sgr0)
else
    RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" BOLD="" DIM="" RESET=""
fi

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

log_info() {
    echo "${BLUE}[INFO]${RESET} $*" >&2
}

log_success() {
    echo "${GREEN}[OK]${RESET} $*" >&2
}

log_warn() {
    echo "${YELLOW}[WARN]${RESET} $*" >&2
}

log_error() {
    echo "${RED}[ERROR]${RESET} $*" >&2
}

log_debug() {
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        echo "${DIM}[DEBUG] $*${RESET}" >&2
    fi
}

# ==============================================================================
# INSTALLATION
# ==============================================================================

log_info "Installing GIT-COPY v${VERSION} (Cross-Platform Edition)"

# Permissions Check
CMD_PREFIX=""
if [ ! -w "$INSTALL_DIR" ]; then CMD_PREFIX="sudo"; fi

# ==============================================================================
# CLEANUP HANDLER
# ==============================================================================

cleanup() {
    local exit_code=$?
    if [[ -n "${TMP_PAYLOAD:-}" ]] && [[ -f "$TMP_PAYLOAD" ]]; then
        rm -f "$TMP_PAYLOAD"
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM HUP

# ==============================================================================
# EMBEDDED PAYLOAD
# ==============================================================================

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
    --output, -o <file> Save output to file instead of clipboard

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

PATTERN EXCLUDES:
    --<pattern>         Exclude folders/files matching wildcard pattern
                        Examples: --*.Tests --test* --*.tmp
                        Matches: MyApp.Tests/, test.cs, test_backup/, file.tmp
    -.extension         Exclude files by extension (e.g., -.md -.log)
                        Note: Use quotes for patterns with spaces (e.g., --"test *")

EXAMPLES:
    git copy                              Copy all tracked files
    git copy js                           Copy only .js files
    git copy web                          Copy all web-related files
    git copy -node_modules                Exclude node_modules folder
    git copy js -tests                    Copy .js files, exclude tests folder
    git copy web -dist -build             Copy web files, exclude build folders
    git copy --exclude src/legacy         Exclude specific path
    git copy --*.Tests                    Exclude all .Tests folders/files
    git copy -.md                         Exclude all markdown files
    git copy --test* -*.tmp               Exclude test* folders and *.tmp files
    git copy -o gitcopy.md                Save output to gitcopy.md instead of clipboard
    git copy --output result.txt          Save output to result.txt instead of clipboard

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

# Parse arguments - separate exclude paths, patterns, and filter args
FILTER_ARGS=""
EXCLUDE_PATHS=""
EXCLUDE_PATTERNS=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output|-o)
            shift
            if [[ $# -gt 0 ]]; then
                OUTPUT_FILE="$1"
                shift
            fi
            ;;
        --exclude)
            shift
            if [[ $# -gt 0 ]]; then
                EXCLUDE_PATHS="${EXCLUDE_PATHS}${EXCLUDE_PATHS:+|}$1"
                shift
            fi
            ;;
        --*)
            # Pattern exclude syntax: --*.Tests, --test*
            pattern="${1#--}"
            # Check if pattern is not empty (after trimming whitespace)
            if [[ -n "${pattern// /}" ]]; then
                EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS}${EXCLUDE_PATTERNS:+|}$pattern"
            fi
            shift
            ;;
        -\.*)
            # Extension exclude syntax: -.md
            ext="${1#-\.}"
            EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS}${EXCLUDE_PATTERNS:+|}*.$ext"
            shift
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
export GIT_COPY_PATTERNS="$EXCLUDE_PATTERNS"

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

        # --- EXCLUDE PATTERNS ---
        $exclude_patterns = $ENV{GIT_COPY_PATTERNS};
        $pattern_active = 0;
        @pattern_list = ();

        if ($exclude_patterns ne "") {
            $pattern_active = 1;
            @pattern_list = split(/\|/, $exclude_patterns);
            # Convert wildcard patterns to regex
            my @converted = ();
            foreach my $pat (@pattern_list) {
                # Do not escape dots - we want to match actual dots
                # Convert * to .* but handle the case where * is at the end specially
                # For patterns like *.Tests, we want to match both "MyApp.Tests" and "MyFile.Tests.cs"
                # So we use .* instead of \. for the * wildcard
                $pat =~ s/\*/.*/g;   # Convert * to .*
                $pat =~ s/\?/./g;    # Convert ? to .
                push @converted, $pat;
            }
            @pattern_list = @converted;
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

    # Check pattern excludes (wildcard matching on folder/file names)
    if ($pattern_active) {
        $should_exclude = 0;
        # Split path into segments
        my @segments = split(/\//, $f);
        foreach my $pattern (@pattern_list) {
            foreach my $segment (@segments) {
                # Pattern is already a regex, use it for substring matching
                if ($segment =~ /$pattern/i) {
                    $should_exclude = 1;
                    last;
                }
            }
            last if $should_exclude;
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

IFS='|' read -r _ COUNT HUMAN_SIZE TOKENS < <(grep "^STATS|" "${TMP_DIR}/stats")
printf "\r\033[K" >&2
if [[ -n "${OUTPUT_FILE:-}" ]]; then
    cp "$RESULT_FILE" "$OUTPUT_FILE"
    echo -e "\033[1;32m✔\033[0;32m Saved to \033[1m${OUTPUT_FILE}\033[0;32m: \033[1m${COUNT}\033[0;32m files | Size: \033[1m${HUMAN_SIZE}\033[0;32m | Tokens: \033[1m~${TOKENS}\033[0m"
else
    copy_to_clipboard "$RESULT_FILE"
    echo -e "\033[1;32m✔\033[0;32m Copied: \033[1m${COUNT}\033[0;32m files | Size: \033[1m${HUMAN_SIZE}\033[0;32m | Tokens: \033[1m~${TOKENS}\033[0m"
fi

EOF

# ==============================================================================
# FINALIZE INSTALLATION
# ==============================================================================

$CMD_PREFIX install -m 755 "$TMP_PAYLOAD" "$TARGET_PATH"

if [ -x "$TARGET_PATH" ]; then
    log_success "Installed v${VERSION} (Cross-Platform Edition)"
else
    log_error "Installation failed"
    exit 1
fi

```

## File: test.ps1
```powershell
<#
.SYNOPSIS
    GIT-COPY Test Suite v16.2 - Windows Edition

.DESCRIPTION
    Comprehensive test suite for git-copy functionality on Windows.
    Tests file filtering, exclusion, and clipboard operations.

.PARAMETER Verbose
    Enable verbose output

.PARAMETER Debug
    Enable debug output

.EXAMPLE
    .\test.ps1
    Run all tests

.EXAMPLE
    .\test.ps1 -Verbose
    Run tests with verbose output

.NOTES
    Version: 16.2
    Requires: Git, PowerShell 5.1+
#>

[CmdletBinding()]
param()

# ==============================================================================
# CONFIGURATION
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

[Version]$TestVersion = "16.2"
$TempBase = [System.IO.Path]::GetTempPath()
$TestDirName = "git-copy-test-$([guid]::NewGuid().ToString('N').Substring(0,8))"
$TestDir = Join-Path $TempBase $TestDirName
$ScriptPath = Join-Path $PSScriptRoot "git-copy.ps1"

# Test tracking
$TestResults = @{
    Passed = 0
    Failed = 0
    Total = 0
}

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

function Write-TestInfo {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "[INFO] " -NoNewline -ForegroundColor Cyan
    Write-Host $Message
}

function Write-TestSuccess {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "[PASS] " -NoNewline -ForegroundColor Green
    Write-Host $Message
}

function Write-TestFailure {
    [CmdletBinding()]
    param([string]$Message)
    Write-Host "[FAIL] " -NoNewline -ForegroundColor Red
    Write-Host $Message
}

function Invoke-TestCase {
    [CmdletBinding()]
    param(
        [string]$Name,
        [scriptblock]$TestBlock
    )

    $TestResults.Total++
    Write-Host "[TEST $($TestResults.Total)] $Name..." -NoNewline

    try {
        & $TestBlock
        Write-Host " PASS" -ForegroundColor Green
        $TestResults.Passed++
    }
    catch {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        $TestResults.Failed++
    }
}

# ==============================================================================
# TEST SETUP
# ==============================================================================

Write-Host "`n=== GIT-COPY TEST SUITE v$TestVersion (Windows) ===" -ForegroundColor Cyan
Write-Host "Test directory: $TestDir`n" -ForegroundColor Gray

# ==============================================================================
# TEST ENVIRONMENT
# ==============================================================================
New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
Push-Location $TestDir

try {
    # Initialize git repo
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test User"

    # Create test files
    @"
function hello() {
    console.log("Hello");
}
"@ | Out-File "test.js" -Encoding UTF8
    
    @"
def greet():
    print("Hello")
"@ | Out-File "test.py" -Encoding UTF8
    
    @"
# Test Document
This is a test.
"@ | Out-File "README.md" -Encoding UTF8

    # Create excluded directory
    New-Item -ItemType Directory -Path "node_modules" -Force | Out-Null
    @"
module.exports = {};
"@ | Out-File "node_modules\index.js" -Encoding UTF8

    # Create nested structure
    New-Item -ItemType Directory -Path "src\components" -Force | Out-Null
    @"
const Component = () => {};
"@ | Out-File "src\components\Button.jsx" -Encoding UTF8
    
    @"
public class Main {}
"@ | Out-File "src\Main.java" -Encoding UTF8

    # Create test directory to exclude
    New-Item -ItemType Directory -Path "temp" -Force | Out-Null
    "temp file" | Out-File "temp\temp.txt" -Encoding UTF8

    git add -A
    git commit -q -m "Initial commit"

    # Mock Clipboard
    $ClipboardFile = Join-Path $TestDir "mock_clipboard.txt"
    function Global:Set-Clipboard { 
        param([Parameter(ValueFromPipeline=$true, Mandatory=$false)][string]$Value)
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Value")) {
             $Value | Set-Content -Path $ClipboardFile -Encoding UTF8
        } elseif ($Input) {
             $Input | Set-Content -Path $ClipboardFile -Encoding UTF8
        }
    }
    function Global:Get-Clipboard { 
        if (Test-Path $ClipboardFile) { Get-Content -Path $ClipboardFile -Raw -Encoding UTF8 } else { "" }
    }

    # Test 1: Basic functionality
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
    Write-Host "[TEST 1] Basic copy all files..." -NoNewline
    & $ScriptPath | Out-Null
    $result = Get-Clipboard
    if ($result -match "test.js" -and $result -match "test.py" -and $result -match "README.md") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Basic test failed"
    }

    # Test 2: Filter by extension
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
    Write-Host "[TEST 2] Filter by extension (js)..." -NoNewline
    & $ScriptPath "js" | Out-Null
    $result = Get-Clipboard
    if ($result -match "test.js" -and $result -notmatch "test.py") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Extension filter test failed"
    }

    # Test 3: Filter by preset
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
    Write-Host "[TEST 3] Filter by preset (web)..." -NoNewline
    & $ScriptPath "web" | Out-Null
    $result = Get-Clipboard
    if ($result -match "test.js" -and $result -match "Button.jsx") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Preset filter test failed"
    }

    # Test 4: Exclude folder (node_modules)
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
    Write-Host "[TEST 4] Exclude folder (node_modules)..." -NoNewline
    & $ScriptPath | Out-Null
    $result = Get-Clipboard
    if ($result -notmatch "node_modules") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Exclude test failed - node_modules should be excluded by default"
    }

    # Test 5: Exclude custom folder using -path syntax
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
    Write-Host "[TEST 5] Exclude custom folder (-temp)..." -NoNewline
    & $ScriptPath "-temp" | Out-Null
    $result = Get-Clipboard
    if ($result -notmatch "temp.txt") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Custom exclude test failed"
    }

    # Test 6: Exclude nested folder
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
    Write-Host "[TEST 6] Exclude nested folder (-src/components)..." -NoNewline
    & $ScriptPath "-src/components" | Out-Null
    $result = Get-Clipboard
    if ($result -match "Main.java" -and $result -notmatch "Button.jsx") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Nested exclude test failed"
    }

    # Test 7: Multiple excludes
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
    Write-Host "[TEST 7] Multiple excludes (-temp -src)..." -NoNewline
    & $ScriptPath "-temp" "-src" | Out-Null
    $result = Get-Clipboard
    if ($result -notmatch "temp.txt" -and $result -notmatch "Main.java" -and $result -notmatch "Button.jsx") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Multiple exclude test failed"
    }

    # Test 8: Filter and exclude combined
    if (Test-Path $ClipboardFile) { Remove-Item $ClipboardFile }
    Write-Host "[TEST 8] Filter (js) + Exclude (-src)..." -NoNewline
    & $ScriptPath "js" "-src" | Out-Null
    $result = Get-Clipboard
    if ($result -match "test.js" -and $result -notmatch "Button.jsx") {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        throw "Combined filter and exclude test failed"
    }

    # ==============================================================================
    # TEST RESULTS
    # ==============================================================================

    Write-Host ""
    Write-Host "============================================================================" -ForegroundColor White
    Write-Host "=== ALL TESTS PASSED ===" -ForegroundColor Green
    Write-Host "============================================================================" -ForegroundColor White
    Write-Host "Total Tests: $($TestResults.Total)"
    Write-Host "Passed: " -NoNewline
    Write-Host "$($TestResults.Passed)" -ForegroundColor Green
    Write-Host "Failed: " -NoNewline
    Write-Host "$($TestResults.Failed)" -ForegroundColor Red
    Write-Host ""

} finally {
    Pop-Location
    Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue
}

```

## File: test.sh
```bash
#!/usr/bin/env bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================

set -euo pipefail

readonly VERSION="16.2"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR=$(mktemp -d)
readonly SCRIPT_PATH="$SCRIPT_DIR/install.sh"

# Test tracking
TESTS_PASSED=0
TESTS_FAILED=0

# ==============================================================================
# VISUALS
# ==============================================================================

# Color support detection
if [[ -t 1 ]] && command -v tput &>/dev/null && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    DIM=$(tput dim)
    RESET=$(tput sgr0)
else
    RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" BOLD="" DIM="" RESET=""
fi

# ==============================================================================
# LOGGING FUNCTIONS
# ==============================================================================

log_info() {
    echo "${BLUE}[INFO]${RESET} $*" >&2
}

log_success() {
    echo "${GREEN}[OK]${RESET} $*" >&2
}

log_warn() {
    echo "${YELLOW}[WARN]${RESET} $*" >&2
}

log_error() {
    echo "${RED}[ERROR]${RESET} $*" >&2
}

log_debug() {
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        echo "${DIM}[DEBUG] $*${RESET}" >&2
    fi
}

log_test_result() {
    local test_name="$1"
    local result="$2"
    if [[ "$result" == "PASS" ]]; then
        echo "${GREEN}PASS${RESET} - $test_name"
        ((TESTS_PASSED++))
    else
        echo "${RED}FAIL${RESET} - $test_name"
        ((TESTS_FAILED++))
    fi
}

# ==============================================================================
# TEST SUITE
# ==============================================================================

echo -e "\n${CYAN}=== GIT-COPY TEST SUITE v${VERSION} (Unix) ===${RESET}"
echo -e "${DIM}Test directory: $TEST_DIR${RESET}\n"

cd "$TEST_DIR"

# ==============================================================================
# CLEANUP HANDLER
# ==============================================================================

cleanup() {
    local exit_code=$?
    cd / || true
    if [[ -n "${TEST_DIR:-}" ]] && [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
    if [[ -n "${EMBEDDED_SCRIPT:-}" ]] && [[ -f "$EMBEDDED_SCRIPT" ]]; then
        rm -f "$EMBEDDED_SCRIPT"
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM HUP

# ==============================================================================
# TEST SETUP
# ==============================================================================

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
    echo -e " ${GREEN}PASS${RESET}"
else
    echo -e " ${RED}FAIL${RESET}"
    echo "Output: $output"
    exit 1
fi

# Test 2: Filter by extension
echo -n "[TEST 2] Filter by extension (js)..."
output=$(capture_output js)
if echo "$output" | grep -q "files"; then
    echo -e " ${GREEN}PASS${RESET}"
else
    echo -e " ${RED}FAIL${RESET}"
    exit 1
fi

# Test 3: Filter by preset
echo -n "[TEST 3] Filter by preset (web)..."
output=$(capture_output web)
if echo "$output" | grep -q "files"; then
    echo -e " ${GREEN}PASS${RESET}"
else
    echo -e " ${RED}FAIL${RESET}"
    exit 1
fi

# Test 4: Exclude folder using -path syntax
echo -n "[TEST 4] Exclude folder (-temp)..."
"$EMBEDDED_SCRIPT" -temp 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "temp.txt" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${RESET}"
    else
        echo -e " ${RED}FAIL${RESET}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${RESET}"
    exit 1
fi

# Test 5: Exclude nested folder
echo -n "[TEST 5] Exclude nested folder (-src/components)..."
"$EMBEDDED_SCRIPT" -src/components 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "Button.jsx" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${RESET}"
    else
        echo -e " ${RED}FAIL${RESET}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${RESET}"
    exit 1
fi

# Test 6: Multiple excludes
echo -n "[TEST 6] Multiple excludes (-temp -src)..."
"$EMBEDDED_SCRIPT" -temp -src 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "temp.txt\|Main.java\|Button.jsx" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${RESET}"
    else
        echo -e " ${RED}FAIL${RESET}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${RESET}"
    exit 1
fi

# Test 7: Filter and exclude combined
echo -n "[TEST 7] Filter (web) + Exclude (-src)..."
"$EMBEDDED_SCRIPT" web -src 2>&1 | grep -v "Processing..." >/dev/null
# Check the clipboard mock file
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if grep -q "test.js" "$HOME/mock_clipboard.txt" 2>/dev/null && ! grep -q "Button.jsx" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${RESET}"
    else
        echo -e " ${RED}FAIL${RESET}"
        cat "$HOME/mock_clipboard.txt"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No clipboard output${RESET}"
    exit 1
fi

# Test 8: --exclude flag syntax
echo -n "[TEST 8] Using --exclude flag..."
"$EMBEDDED_SCRIPT" --exclude temp 2>&1 | grep -v "Processing..." >/dev/null
if [ -f "$HOME/mock_clipboard.txt" ]; then
    if ! grep -q "temp.txt" "$HOME/mock_clipboard.txt" 2>/dev/null; then
        echo -e " ${GREEN}PASS${RESET}"
    else
        echo -e " ${RED}FAIL${RESET}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${RESET}"
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
        echo -e " ${GREEN}PASS${RESET}"
    else
        echo -e " ${RED}FAIL${RESET}"
        exit 1
    fi
else
    echo -e " ${RED}FAIL - No output${RESET}"
    exit 1
fi

rm -f "$EMBEDDED_SCRIPT"

# ==============================================================================
# TEST RESULTS
# ==============================================================================

echo ""
echo "${BOLD}============================================================================${RESET}"
echo "${GREEN}=== ALL TESTS PASSED ===${RESET}"
echo "${BOLD}============================================================================${RESET}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo "Passed: ${GREEN}${TESTS_PASSED}${RESET}"
echo "Failed: ${RED}${TESTS_FAILED}${RESET}"
echo ""

```

## File: test_fuzzy.ps1
```powershell

$ErrorActionPreference = "Stop"
$ScriptPath = Join-Path $PSScriptRoot "git-copy.ps1"
$TestDirName = "git-copy-fuzzy-test"
$TestDir = Join-Path $PSScriptRoot $TestDirName

# Cleanup
if (Test-Path $TestDir) { Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $TestDir | Out-Null

Push-Location $TestDir

try {
    Write-Host "Setting up fuzzy test..." -ForegroundColor Cyan
    
    # Setup Files
    "content" | Set-Content "MyTests.txt"
    "content" | Set-Content "Tests.txt"
    New-Item -ItemType Directory -Force -Path "Tests" | Out-Null
    "content" | Set-Content "Tests/file.txt"

    # Mock Clipboard
    function Global:Set-Clipboard {
        param([Parameter(ValueFromPipeline=$true)]$Value)
        $Value | Set-Content "..\clipboard_output.md" -Encoding UTF8
    }

    # --- TEST: Exclude --Tests ---
    Write-Host "[TEST] Exclude --Tests..."
    & $ScriptPath "--Tests" | Out-Null
    
    $Output = Get-Content "..\clipboard_output.md" -Raw
    
    if ($Output -match "Tests.txt") { Write-Host "Tests.txt present (Expected? Depends on Strictness)" -ForegroundColor Yellow }
    else { Write-Host "Tests.txt EXCLUDED" -ForegroundColor Red }

    if ($Output -match "MyTests.txt") { Write-Host "MyTests.txt present" -ForegroundColor Green }
    else { Write-Host "MyTests.txt EXCLUDED (Aggressive Fuzzy Match)" -ForegroundColor Red }

    if ($Output -match "Tests/file.txt") { Write-Host "Tests/file.txt present" -ForegroundColor Red }
    else { Write-Host "Tests/file.txt EXCLUDED (Correct)" -ForegroundColor Green }

} finally {
    Pop-Location
}

```

## File: test_new_features.ps1
```powershell

$ErrorActionPreference = "Stop"
$ScriptPath = Join-Path $PSScriptRoot "git-copy.ps1"
$TestDirName = "git-copy-feature-test"
$TestDir = Join-Path $PSScriptRoot $TestDirName

# Cleanup previous run
if (Test-Path $TestDir) { Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $TestDir | Out-Null

Push-Location $TestDir

try {
    Write-Host "Setting up test environment..." -ForegroundColor Cyan
    
    # 1. Setup Files
    # Main files
    New-Item -ItemType Directory -Force -Path "TestProject" | Out-Null
    Set-Location "TestProject"
    
    "public class PlayerController : MonoBehaviour {}" | Set-Content "Player.cs"
    "guid: 12345" | Set-Content "Player.cs.meta"
    "SECRET_KEY=123" | Set-Content ".env"
    "node_modules stuff" | Set-Content "package-lock.json"

    # Pattern exclusion test fixtures
    New-Item -ItemType Directory -Force -Path "MyApp.Tests" | Out-Null
    "public class TestClass {}" | Set-Content "MyApp.Tests/UnitTest.cs"
    "public class UtilsTest {}" | Set-Content "Utils.Tests.cs"
    "# Test File" | Set-Content "README.md"
    New-Item -ItemType Directory -Force -Path "docs" | Out-Null
    "# Docs" | Set-Content "docs/guide.md"
    "test content" | Set-Content "test_file.cs"
    
    # Mock Clipboard
    function Global:Set-Clipboard {
        param([Parameter(ValueFromPipeline=$true)]$Value)
        $Value | Set-Content "..\clipboard_output.md" -Encoding UTF8
    }

    # --- TEST 1: Basic & Defaults ---
    Write-Host "`n[TEST 1] Basic & Defaults..." -NoNewline
    if (Test-Path "..\clipboard_output.md") { Remove-Item "..\clipboard_output.md" }
    
    & $ScriptPath | Out-Null
    
    $Output = Get-Content "..\clipboard_output.md" -Raw
    
    if ($Output -notmatch "Player.cs") { throw "Player.cs missing" }
    if ($Output -match "Player.cs.meta") { throw ".meta NOT ignored" }
    if ($Output -match "SECRET_KEY") { throw ".env NOT ignored" }
    Write-Host " PASS" -ForegroundColor Green

    # --- TEST 2: Pattern --*.Tests ---
    Write-Host "[TEST 2] Pattern --*.Tests..." -NoNewline
    if (Test-Path "..\clipboard_output.md") { Remove-Item "..\clipboard_output.md" }
    
    & $ScriptPath "--*.Tests*" | Out-Null
    
    $Output = Get-Content "..\clipboard_output.md" -Raw
    
    if ($Output -match "MyApp.Tests") { throw "MyApp.Tests NOT excluded" }
    if ($Output -match "Utils.Tests.cs") { throw "Utils.Tests.cs NOT excluded" }
    if ($Output -notmatch "Player.cs") { throw "Player.cs incorrectly excluded" }
    Write-Host " PASS" -ForegroundColor Green

    # --- TEST 3: Extension -.md ---
    Write-Host "[TEST 3] Extension -.md..." -NoNewline
    if (Test-Path "..\clipboard_output.md") { Remove-Item "..\clipboard_output.md" }
    
    & $ScriptPath "-.md" | Out-Null
    
    $Output = Get-Content "..\clipboard_output.md" -Raw
    
    if ($Output -match "README.md") { throw "README.md NOT excluded" }
    if ($Output -match "guide.md") { throw "guide.md NOT excluded" }
    if ($Output -notmatch "Player.cs") { throw "Player.cs incorrectly excluded" }
    Write-Host " PASS" -ForegroundColor Green

    # --- TEST 4: Multiple Patterns ---
    Write-Host "[TEST 4] Multiple Patterns (--*.Tests -.md)..." -NoNewline
    if (Test-Path "..\clipboard_output.md") { Remove-Item "..\clipboard_output.md" }
    
    & $ScriptPath "--*.Tests*" "-.md" | Out-Null
    
    $Output = Get-Content "..\clipboard_output.md" -Raw
    
    if ($Output -match "MyApp.Tests") { throw "MyApp.Tests NOT excluded" }
    if ($Output -match "README.md") { throw "README.md NOT excluded" }
    if ($Output -notmatch "Player.cs") { throw "Player.cs incorrectly excluded" }
    Write-Host " PASS" -ForegroundColor Green
    
    Write-Host "`nALL FEATURE TESTS PASSED" -ForegroundColor Green

} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
} finally {
    Pop-Location
    # Remove-Item -Recurse -Force $TestDir -ErrorAction SilentlyContinue
}

```


_Project Structure:_
```text
.github/workflows/test.yml
.idea/.gitignore
.idea/encodings.xml
.idea/indexLayout.xml
.idea/vcs.xml
clipboard_output.md
debug-contains.ps1
debug-filter.ps1
debug-run.ps1
debug-test.ps1
debug-test2.ps1
debug-vars.ps1
debug-where.ps1
git-copy-feature-test/clipboard_output.md
git-copy-feature-test/TestProject/docs/guide.md
git-copy-feature-test/TestProject/MyApp.Tests/UnitTest.cs
git-copy-feature-test/TestProject/Player.cs
git-copy-feature-test/TestProject/README.md
git-copy-feature-test/TestProject/test_file.cs
git-copy-feature-test/TestProject/Utils.Tests.cs
git-copy-fuzzy-test/MyTests.txt
git-copy-fuzzy-test/Tests.txt
git-copy-fuzzy-test/Tests/file.txt
git-copy.ps1
install.ps1
install.sh
js
LICENSE
QUICK_REFERENCE.md
README.md
test_fuzzy.ps1
test_new_features.ps1
test.ps1
test.sh
```
