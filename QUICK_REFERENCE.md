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
