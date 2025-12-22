# Contributing to git-copy

Thank you for your interest in contributing to git-copy! This document provides guidelines and instructions for contributors.

## 🧪 Testing

We maintain comprehensive cross-platform test suites to ensure reliability across Windows, macOS, and Linux.

### Running Tests

**Unix (macOS/Linux):**
```bash
./test.sh
```

**Windows (PowerShell):**
```powershell
.\test.ps1
```

### Test Coverage

Our tests verify:
- ✅ Basic file copying functionality
- ✅ Extension-based filtering (`.js`, `.py`, etc.)
- ✅ Preset filtering (`web`, `backend`, etc.)
- ✅ Folder exclusion (`-node_modules`, `-tests`)
- ✅ Nested path exclusion (`-src/components`)
- ✅ Multiple exclusions combined
- ✅ Filter + exclusion combinations
- ✅ Security file filtering (`.env`, `.pem`, etc.)

### Before Submitting PRs

1. **Run tests on your platform** - Ensure all tests pass
2. **Test manually** - Try your changes in a real repository
3. **Check edge cases** - Empty repos, large files, special characters
4. **Update documentation** - Keep README.md in sync with changes

## 🏗️ Architecture

### File Structure

```
git-copy/
├── git-copy.ps1      # Windows PowerShell implementation
├── install.sh        # Unix installer (embeds bash script)
├── install.ps1       # Windows installer
├── test.sh           # Unix test suite
├── test.ps1          # Windows test suite
└── README.md         # User documentation
```

### How It Works

**Unix Version (Bash + Perl):**
1. Uses `git ls-files` to discover tracked files
2. Perl processes files in a single pass (efficient)
3. Applies filters, exclusions, and security checks
4. Outputs formatted markdown with syntax highlighting
5. Copies to clipboard using platform-specific tools

**Windows Version (PowerShell):**
1. Uses `git ls-files` or fallback to `Get-ChildItem`
2. Processes files in PowerShell loop
3. Applies same filters and exclusions as Unix version
4. Uses `Set-Clipboard` for clipboard operations
5. Handles UTF-8 encoding carefully to avoid crashes

### Key Design Principles

- **Cross-platform parity** - Both versions should behave identically
- **Git-aware** - Respects `.gitignore` and tracks only versioned files
- **Secure by default** - Never copy secrets, keys, or credentials
- **Performance** - Handle large repos efficiently
- **User-friendly** - Clear output, helpful error messages

## 🛠️ Development Guidelines

### Code Style

**PowerShell:**
- Use PascalCase for variables
- Comment complex regex patterns
- Handle errors with try/catch
- Use `$ErrorActionPreference = "Stop"`

**Bash:**
- Use lowercase_with_underscores for variables
- Set strict mode: `set -o nounset -o pipefail`
- Quote variables to prevent word splitting
- Use `[[ ]]` for conditionals

**Perl (embedded in install.sh):**
- Keep the embedded Perl readable
- Comment regex patterns
- Use meaningful variable names
- Match behavior with PowerShell version

### Adding New Features

When adding features, ensure:

1. **Both implementations updated** - PowerShell AND Bash/Perl
2. **Tests added** - Add test cases to both test.sh and test.ps1
3. **Documentation updated** - Update README.md and help text
4. **Backward compatible** - Don't break existing workflows

### Common Changes

**Adding a new preset:**
1. Add to `$Presets` in `git-copy.ps1`
2. Add to `%presets` in `install.sh` (Perl section)
3. Update help text in both scripts
4. Update README.md examples
5. Add test case if needed

**Adding an exclusion pattern:**
1. Update `$IgnoreRegex` in `git-copy.ps1`
2. Update `$ignore_re` in `install.sh` (Perl section)
3. Document in README.md security section
4. Add test to verify exclusion works

**Improving clipboard support:**
1. Update `copy_to_clipboard()` in `install.sh`
2. Update clipboard usage in `git-copy.ps1`
3. Test on target platform
4. Update requirements in README.md

## 🐛 Reporting Issues

When reporting bugs, include:

- **Platform**: Windows 10/11, macOS version, Linux distro
- **PowerShell version** (Windows): Run `$PSVersionTable.PSVersion`
- **Bash version** (Unix): Run `bash --version`
- **Git version**: Run `git --version`
- **Command used**: Exact command that failed
- **Error message**: Full error output
- **Repository type**: Public repo URL or description

## 📋 Pull Request Process

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes** - Follow code style guidelines
4. **Run tests**: Ensure `test.sh` or `test.ps1` passes
5. **Test manually**: Try in a real repository
6. **Update docs**: Keep README.md synchronized
7. **Commit**: Use clear, descriptive commit messages
8. **Push**: Push to your fork
9. **Open PR**: Describe changes and why they're needed

### PR Checklist

- [ ] Tests pass on target platform(s)
- [ ] Both implementations updated (if applicable)
- [ ] Documentation updated
- [ ] No breaking changes (or clearly documented)
- [ ] Code follows style guidelines
- [ ] Commit messages are clear

## 🌍 Cross-Platform Considerations

### Path Separators
- Windows uses `\`, Unix uses `/`
- Normalize paths in code, use appropriate separator
- Git outputs Unix-style paths even on Windows

### Line Endings
- Git handles CRLF/LF conversion
- PowerShell outputs CRLF by default
- Bash uses LF

### Encoding
- Always use UTF-8
- PowerShell: Set `$OutputEncoding = [System.Text.Encoding]::UTF8`
- Bash: Generally UTF-8 by default

### Clipboard Tools
- macOS: `pbcopy`
- Linux X11: `xclip` or `xsel`
- Linux Wayland: `wl-copy`
- Windows: `Set-Clipboard` (PowerShell)
- WSL: `clip.exe`
- SSH/tmux: OSC 52 escape sequences

## 🎯 Priority Areas for Contribution

We especially welcome contributions in:

- **Performance improvements** - Faster file processing
- **New presets** - Language-specific file groups
- **Clipboard support** - Additional platforms or terminals
- **Error handling** - Better error messages
- **Documentation** - Examples, tutorials, translations
- **CI/CD** - Improved GitHub Actions workflows

## 📞 Getting Help

- **Issues**: Open a GitHub issue for bugs or questions
- **Discussions**: Use GitHub Discussions for general questions
- **Pull Requests**: We review PRs regularly

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to git-copy!** 🙏
