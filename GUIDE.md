# Installing aider-chat on Termux (Android/ARM64)

> **Status: ✅ Working**  
> Device: Android, aarch64, ~7.3GB RAM  
> aider version: 0.86.2  
> Model: moonshotai/kimi-k2.5 via Nvidia API  
> Date: February 2026

---

## Why All These Heavy Packages?

aider-chat is not just a chat interface — it includes a **repository map** feature that analyzes your entire codebase to give the AI full context of your project structure. This requires:

- **numpy + scipy** — mathematical operations for code graph analysis
- **tokenizers** — fast tokenization to count and manage context window usage
- **tree-sitter + language packs** — parse source code into syntax trees for all supported languages
- **orjson** — fast JSON for handling large code analysis payloads

---

## Why This Document Exists

Installing `aider-chat` on Termux requires building many packages from source because PyPI does not publish pre-built wheels for the `aarch64-linux-android` architecture. This document captures every step, fix, and workaround discovered during the process so that other Termux users don't have to repeat this journey.

---

## System Requirements

- Android device with at least 6GB RAM (8GB+ recommended)
- Termux installed from F-Droid (not Play Store)
- ~5GB free storage for build artifacts
- 6–8GB swapfile (critical — see Step 2)
- Device plugged in (compilation is intensive)

---

## Step 1 — Install System Dependencies

```bash
pkg update && pkg upgrade

pkg install -y \
  clang \
  make \
  cmake \
  rust \
  tree-sitter \
  libjpeg-turbo \
  libpng \
  libwebp \
  libtiff \
  zlib \
  openssl \
  libffi \
  libandroid-spawn \
  flang \
  mold \
  git \
  fzf \
  python
```

### Install sccache (Rust compiler cache)

```bash
cargo install sccache
```

> `sccache` caches Rust compilation — makes rebuilds nearly instant for unchanged code.

---

## Step 2 — Create Swapfile (Critical!)

Android's OOM killer will terminate long compilations without enough swap. 6GB is the minimum recommended:

```bash
dd if=/dev/zero of=$HOME/swapfile bs=1M count=6144
chmod 600 $HOME/swapfile
mkswap $HOME/swapfile
swapon $HOME/swapfile

# Verify
swapon --show
free -h
```

Also run this to prevent Termux from being killed while in background:

```bash
termux-wake-lock
```

---

## Step 3 — Configure ~/.bashrc

Add these permanently so every session is pre-configured:

```bash
cat << 'EOF' >> ~/.bashrc

# === Build Environment ===
export ANDROID_API_LEVEL=24
export UV_LINK_MODE=copy
export CC="clang"
export CXX="clang++"
export LDFLAGS="-L$PREFIX/lib -fuse-ld=$(which mold)"
export CFLAGS="-I$PREFIX/include -O3 -march=native"
export CXXFLAGS="-I$PREFIX/include -O3 -march=native"
export RUSTFLAGS="-C target-cpu=native"
export CARGO_PROFILE_RELEASE_LTO=thin
export CARGO_BUILD_JOBS=4
export MAKEFLAGS="-j4"
export RUSTC_WRAPPER=sccache
export FC=flang
export F77=flang
export PATH="$HOME/.cargo/bin:$PATH"

# === Nvidia API ===
export NVIDIA_API_KEY="your-key-here"

# === History ===
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoredups:erasedups
export HISTTIMEFORMAT='%F %T '

# === Aliases ===
alias av='source .venv/bin/activate'
alias aider='~/aider/.venv/bin/aider --model openai/moonshotai/kimi-k2.5 --openai-api-base https://integrate.api.nvidia.com/v1 --openai-api-key $NVIDIA_API_KEY'
EOF

source ~/.bashrc
```

> **Important flag notes:**
> - `CC="clang"` not `CC="ccache clang"` — setting ccache as the compiler confuses CMake
> - `RUSTFLAGS` must NOT include `-C opt-level=3` — cargo already sets this and duplicates cause a rustc internal compiler error (ICE)
> - `-fuse-ld=$(which mold)` uses the full path — CMake can't find `mold` by name alone
> - `CARGO_BUILD_JOBS=4` — ~50% of cores prevents OOM; adjust with `nproc`

---

## Step 4 — Install uv

```bash
pip install uv
```

---

## Step 5 — Create Virtualenv

```bash
mkdir ~/aider
cd ~/aider
uv venv .venv
source .venv/bin/activate
```

---

## Step 6 — Fix Missing Tree-Sitter Headers

`tree-sitter-c-sharp==0.23.1` requires headers that don't ship with Termux's tree-sitter package. We need to manually provide them.

### 6.1 — Populate the uv cache

Run a partial install first to download source packages into the cache:

```bash
uv pip install --python .venv/bin/python aider-chat
# This will fail — that's expected. We just need the cache populated.
```

### 6.2 — Find and copy the headers

```bash
mkdir -p $PREFIX/include/tree_sitter

# Find the cached tree-sitter-yaml source (hash varies per device)
YAML_SRC=$(find ~/.cache/uv -path "*tree-sitter-yaml*" -name "parser.h" 2>/dev/null | head -1 | xargs dirname)

cp $YAML_SRC/parser.h $PREFIX/include/tree_sitter/
cp $YAML_SRC/alloc.h $PREFIX/include/tree_sitter/
cp $YAML_SRC/array.h $PREFIX/include/tree_sitter/
```

### 6.3 — Patch parser.h for missing types

```bash
# Add missing TSFieldMapSlice struct
echo '
typedef struct {
  uint16_t index;
  uint16_t length;
} TSFieldMapSlice;
' >> $PREFIX/include/tree_sitter/parser.h

# Add version field alias
echo '
#define version abi_version
' >> $PREFIX/include/tree_sitter/parser.h
```

---

## Step 7 — Fix tree-sitter-yaml Missing Scanner

The `tree-sitter-yaml` PyPI package (0.7.2) is missing `scanner.c` in its source distribution — a bug in the package. The compiled binding has undefined symbols for the external scanner, causing a crash on import.

### 7.1 — Download the missing source files

```bash
YAML_HASH=$(ls ~/.cache/uv/sdists-v9/pypi/tree-sitter-yaml/0.7.2/)
YAML_SRC_DIR=~/.cache/uv/sdists-v9/pypi/tree-sitter-yaml/0.7.2/$YAML_HASH/src/src

curl -L "https://raw.githubusercontent.com/tree-sitter-grammars/tree-sitter-yaml/master/src/scanner.c" \
  -o $YAML_SRC_DIR/scanner.c

curl -L "https://raw.githubusercontent.com/tree-sitter-grammars/tree-sitter-yaml/master/src/schema.core.c" \
  -o $YAML_SRC_DIR/schema.core.c
```

### 7.2 — Rebuild tree-sitter-yaml with scanner included

```bash
YAML_HASH=$(ls ~/.cache/uv/sdists-v9/pypi/tree-sitter-yaml/0.7.2/)
cd ~/.cache/uv/sdists-v9/pypi/tree-sitter-yaml/0.7.2/$YAML_HASH/src

pip install setuptools
pip install --no-deps . --no-build-isolation
```

### 7.3 — Copy the fixed binary into the venv

```bash
cp /data/data/com.termux/files/usr/lib/python3.12/site-packages/tree_sitter_yaml/_binding.abi3.so \
   ~/aider/.venv/lib/python3.12/site-packages/tree_sitter_yaml/_binding.abi3.so
```

---

## Step 8 — Build All Dependencies as Wheels

The critical insight for Termux installation: **build everything as wheels first, then install**. Running `uv pip install aider-chat` directly triggers parallel builds that exhaust RAM and get OOM-killed. Also, uv ignores `--find-links` when packages exist on PyPI — use `pip` directly for local wheel installs.

### 8.1 — Build C packages with pip

```bash
cd ~/aider
mkdir -p ~/wheels/linux

pip install --no-deps setuptools wheel
pip wheel --no-deps -w ~/wheels/linux \
  aiohttp cffi markupsafe pillow psutil pyyaml regex \
  tiktoken tree-sitter tree-sitter-c-sharp \
  tree-sitter-embedded-template tree-sitter-language-pack \
  "numpy==1.26.4"
```

### 8.2 — Build Rust packages one at a time

Build each Rust package separately to avoid OOM:

```bash
for pkg in pydantic-core orjson watchfiles fastuuid rpds-py jiter tokenizers; do
  echo "Building $pkg..."
  pip wheel --no-deps -w ~/wheels/linux $pkg && echo "✅ $pkg done" || echo "❌ $pkg failed"
done
```

### 8.3 — Build scipy (needs numpy pinned)

```bash
pip wheel --no-deps -w ~/wheels/linux "scipy==1.15.3"
```

> aider-chat requires exactly `numpy==1.26.4` and `scipy==1.15.3` — these are pinned in its requirements.

### 8.4 — Retag android/manylinux wheels

Some packages build with platform tags that pip rejects on Termux. Retag them all:

```bash
uv pip install --python .venv/bin/python wheel

# Retag any non-linux wheels
for whl in ~/wheels/linux/*android*.whl ~/wheels/linux/*arm64_v8a*.whl ~/wheels/linux/*manylinux*.whl; do
  [ -f "$whl" ] && .venv/bin/python -m wheel tags --platform-tag linux_aarch64 "$whl"
done

# Remove old tagged versions
rm -f ~/wheels/linux/*android*.whl ~/wheels/linux/*arm64_v8a*.whl ~/wheels/linux/*manylinux*.whl
```

### 8.5 — Install all wheels

```bash
pip install --no-deps ~/wheels/linux/*.whl
```

---

## Step 9 — Install aider-chat

With all dependencies pre-installed, aider-chat itself installs quickly:

```bash
uv pip install --python .venv/bin/python aider-chat
```

---

## Step 10 — Configure Model Settings

Create `~/.aider.model.settings.yml` to tell aider about kimi-k2.5's capabilities:

```bash
cat << 'EOF' > ~/.aider.model.settings.yml
- name: openai/moonshotai/kimi-k2.5
  edit_format: diff
  use_repo_map: true
  examples_as_sys_msg: true
  use_temperature: true
  streaming: true
  extra_params:
    temperature: 1.0
    max_tokens: 16384
    top_p: 1.0
    chat_template_kwargs:
      thinking: true
EOF
```

Create `~/.aider.model.metadata.json` for context window info:

```bash
cat << 'EOF' > ~/.aider.model.metadata.json
{
    "openai/moonshotai/kimi-k2.5": {
        "max_input_tokens": 200000,
        "max_output_tokens": 16384,
        "input_cost_per_token": 0,
        "output_cost_per_token": 0
    }
}
EOF
```

> **Why `openai/` prefix?** litellm requires a provider prefix to route API calls correctly. `openai/` tells it to use the OpenAI-compatible API format, which Nvidia's endpoint supports. Without it you get `LLM Provider NOT provided` error.

> **Why `thinking: true`?** kimi-k2.5 supports a reasoning/thinking mode that significantly improves code quality.

---

## Step 11 — Launch aider

```bash
aider
```

Or from any project directory:

```bash
cd ~/myproject
aider
```

---

## Packages That Need Building From Source

| Package | Type | Notes |
|---------|------|-------|
| numpy 1.26.4 | C/Fortran | Pinned version required by aider |
| scipy 1.15.3 | C/Fortran | Pinned version required by aider |
| pillow | C | Needs libjpeg-turbo |
| pyyaml | C | |
| cffi | C | |
| regex | C | |
| aiohttp | C | |
| tiktoken | C+Rust | |
| tree-sitter | C | |
| tree-sitter-c-sharp | C | Requires header patches (Step 6) |
| tree-sitter-yaml | C | Requires scanner.c download from GitHub (Step 7) |
| tree-sitter-language-pack | C | Requires manylinux retag (Step 8.4) |
| pydantic-core | Rust | |
| tokenizers | Rust | |
| orjson | Rust | |
| rpds-py | Rust | |
| watchfiles | Rust | |
| fastuuid | Rust | |
| jiter | Rust | |

---

## Known Issues & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `rustc ICE` / internal compiler error | Duplicate `-C opt-level=3` in RUSTFLAGS | Remove from RUSTFLAGS, cargo sets it already |
| `invalid linker name -fuse-ld=mold` | CMake can't find mold by name | Use `LDFLAGS="-fuse-ld=$(which mold)"` |
| `ccache treated as compiler` | `CC="ccache clang"` confuses CMake | Set `CC="clang"` only |
| `Failed to determine Android API level` | Missing env var | Set `export ANDROID_API_LEVEL=24` |
| `tree_sitter/parser.h not found` | Missing headers | Copy from tree-sitter-yaml cache (Step 6) |
| `TSFieldMapSlice unknown type` | Old parser.h | Append struct definition to parser.h |
| `version field not found in TSLanguage` | Field name mismatch | Add `#define version abi_version` |
| `cannot locate symbol tree_sitter_yaml_external_scanner_create` | scanner.c missing from sdist | Download from GitHub and rebuild (Step 7) |
| `dynamic module does not define PyInit__binding` | Wrong linking approach | Rebuild from source, never link .so files manually |
| Signal 9 / OOM killed | Parallel builds exhaust RAM | Build one package at a time; use 6GB swapfile |
| `Text file busy (os error 26)` | Android /tmp noexec on build scripts | Set `CARGO_TARGET_DIR=$HOME/.cargo/target` |
| `LLM Provider NOT provided` | Missing provider prefix for litellm | Use `openai/` prefix: `openai/moonshotai/kimi-k2.5` |
| android-tagged wheels rejected by pip | Platform tag mismatch | Retag with `python -m wheel tags --platform-tag linux_aarch64` |
| manylinux wheels rejected | Platform tag mismatch | Same retag approach |
| uv ignores `--find-links` | uv prefers rebuilding over local wheels | Use `pip install` directly for local wheels |

---

## Tips for Surviving Long Builds on Android

- Keep Termux in the **foreground** (split screen works)
- Run `termux-wake-lock` before starting
- Close all other apps before Rust package builds
- Create the 6GB swapfile before starting (Step 2)
- Build packages one at a time — parallel builds cause OOM kills
- If a build gets killed, just rerun — sccache will skip already-compiled Rust code

---

## Contribution Targets

### 1. tree-sitter-yaml upstream
Report missing `scanner.c` in sdist:
- https://github.com/tree-sitter-grammars/tree-sitter-yaml

### 2. termux-packages
Submit a build recipe for `aider-chat`:
- https://github.com/termux/termux-packages

### 3. PyPI Wheel Requests
Open issues requesting `aarch64-android` wheel support:
- https://github.com/pydantic/pydantic-core
- https://github.com/huggingface/tokenizers
- https://github.com/ijl/orjson

### 4. aider-chat Upstream
Document Termux compatibility:
- https://github.com/Aider-AI/aider

---

*Document started: February 13, 2026*  
*Completed: February 14, 2026*  
*aider 0.86.2 confirmed working on Android aarch64*
