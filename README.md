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
iwr -useb https://raw.githubusercontent.com/iafahim/git-copy/main/install.ps1 | iex
```

## 🚀 Usage

Once installed, it works as a native Git subcommand. Navigate to any git repository and run:

```bash
# Copy ALL tracked files (smart defaults excludes locks/binaries)
git copy

# Copy specific groups
git copy web        # html, css, js, ts, jsx
git copy backend    # python, ruby, php, go, rust
git copy java       # java, kotlin, scala

# Copy specific file types
git copy js         # only *.js
git copy py rust    # *.py and *.rs

# View Help
git copy --help
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

## 🔧 Manual Install

**Windows:**
1. Download `install.ps1`.
2. Run `.\install.ps1` in PowerShell.

**Mac/Linux:**
1.  Download `install.sh`.
2.  `chmod +x install.sh`
3.  `./install.sh`

---

**License:** MIT  
**Author:** Md. Ishtiaq Ahamed Fahim
```