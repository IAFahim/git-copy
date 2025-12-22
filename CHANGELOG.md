# Changelog

All notable changes to this project will be documented in this file.

## [v16.2] - 2025-12-22

### ✨ Added
- **Folder Exclusion Feature**: Exclude specific folders or paths from being copied
  - Syntax: `-node_modules`, `-tests`, `-src/components`
  - Alternative syntax: `--exclude path`
  - Multiple exclusions supported: `-tests -docs -tmp`
  - Works with filters: `git copy js -tests`

- **Comprehensive Test Suites**: Cross-platform tests for all features
  - `test.sh` for Unix (macOS/Linux)
  - `test.ps1` for Windows (PowerShell)
  - 8 test cases covering filters, exclusions, and combinations
  - Automated testing via GitHub Actions

- **Built-in Help Documentation**: Added `--help` flag
  - Shows usage, options, presets, and examples
  - Available on both Windows and Unix versions
  - `git copy --help` or `git copy -h`

- **CONTRIBUTING.md**: Comprehensive contributor guide
  - Architecture documentation
  - Development guidelines
  - Testing instructions
  - PR process

### 📚 Improved
- **README.md**: Complete rewrite with better structure
  - Detailed usage examples
  - Folder exclusion documentation
  - Windows permissions guide
  - Security features documented
  - Testing section added

### 🔧 Technical
- Cross-platform path exclusion logic
- Normalized path handling (Windows `\` vs Unix `/`)
- Both PowerShell and Bash/Perl implementations updated
- Maintained feature parity across platforms

### 🐛 Fixed
- Heredoc nesting issue in install.sh
- Path separator handling in exclusions
- UTF-8 encoding consistency

## [v16.1] - Previous Release

### Features
- Unity Edition with Unity-specific presets
- Multiple language presets (web, backend, java, cpp, etc.)
- Smart security filtering
- Cross-platform clipboard support
- Git-aware file discovery
- Markdown output with syntax highlighting

---

For full commit history, see the [GitHub repository](https://github.com/iafahim/git-copy).
