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