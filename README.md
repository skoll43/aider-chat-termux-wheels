# aider-chat Termux Wheels

Pre-built Android wheels for **aider-chat 0.86.3.dev53 (git main)** on Termux
(Android aarch64, **Python 3.14**).

> **Status: ✅ Working (August 2026)** — verified on-device and via a
> **fresh install test following these exact instructions**:
> `aider 0.86.3.dev53+g5dc9490bb`, Python 3.14.6, rustc 1.98.0.
> The bundle covers **every binary dependency** (20 wheels) — no compilation
> on the phone. See [UPDATE-2026.md](UPDATE-2026.md) for the full background.

## What you get (and where each piece comes from)

| Piece | Source | Compilation? |
|---|---|---|
| numpy, pillow, psutil, lxml, cryptography | Termux apt (`termux-main`) | no |
| scipy, tokenizers, tiktoken | Termux apt (**TUR** repo) | no |
| 20 binary/pure wheels (Rust, C, tree-sitter, aiohttp family, cffi, regex…) | this repo's release bundle | no |
| ~79 pure-python deps at aider's exact pins | PyPI (`pure-deps-pinned.txt`) | no |
| aider itself | git main (pure Python) | no |
| audioop-lts + 1-line shim | tiny C sdist (seconds) | yes, tiny |

## Prerequisites

```bash
pkg update && pkg upgrade -y
pkg install -y tur-repo && pkg update -y   # TUR: needed for scipy/tokenizers/tiktoken
pkg install -y python unzip wget curl clang
pip install uv
```

> `clang` is only needed for the tiny `audioop-lts` build (step 5). If you skip
> it, audioop (and pydub-based features) won't work.

## Installation

**1. Install the apt-prebuilt heavy deps:**

```bash
pkg install -y python-numpy python-scipy python-pillow python-psutil \
  python-tokenizers python-tiktoken python-cryptography python-lxml
```

**2. Create a venv that sees the apt packages:**

```bash
mkdir -p ~/my-aider-project && cd ~/my-aider-project
uv venv --system-site-packages .venv
source .venv/bin/activate
uv pip install pip setuptools wheel
```

**3. Download and install the wheel bundle (all binary deps):**

```bash
wget https://github.com/skoll43/aider-chat-termux-wheels/releases/download/v0.86.3.dev53-py314/aider-termux-py314-wheels.zip
unzip aider-termux-py314-wheels.zip -d wheels
pip install --no-deps wheels/*.whl
```

**4. Install aider itself (git main — the version that supports Python 3.14):**

```bash
pip install --no-deps "git+https://github.com/Aider-AI/aider.git"
```

**5. Install the pure-python dependencies at aider's exact pins:**

```bash
wget https://raw.githubusercontent.com/skoll43/aider-chat-termux-wheels/main/pure-deps-pinned.txt
pip install -r pure-deps-pinned.txt
```

**6. Runtime stragglers:**

```bash
pip install --only-binary :all: json_logic
pip install --no-deps audioop-lts          # tiny C sdist (needs clang from step 1)
printf 'from audioop import *\n' > .venv/lib/python3.14/site-packages/pyaudioop.py  # pydub shim
```

**7. Verify:**

```bash
aider --version    # aider 0.86.3.dev53+g5dc9490bb
```

Only step left: API keys (`~/.aider.model.settings.yml`,
`~/.aider.model.metadata.json`, `OPENAI_API_KEY` / `DEEPSEEK_API_KEY`).

## Why the pins in `pure-deps-pinned.txt` differ from some installed versions

aider pins most deps exactly, but the binary packages above deliberately use
the apt/repo versions (e.g. `scipy 1.18.1` vs aider's declared `<1.18`,
`tokenizers 0.23.1` vs `0.22.2`). This is **verified to work at runtime** —
aider never enforces these pins because steps 3-5 never let pip re-resolve the
binary packages. Do **not** run a plain `pip install aider-chat` afterwards:
pip would then try to build scipy/tokenizers/tiktoken from source on Android
and fail (no Android wheels exist for them).

## Wheel Contents (`aider-termux-py314-wheels.zip` — 20 wheels)

| Group | Packages |
|-------|----------|
| Rust | pydantic-core 2.41.5, jiter 0.13.0, rpds-py 0.30.0, orjson 3.11.7, watchfiles 1.1.1, fastuuid 0.14.0 |
| C | cffi 2.1.1, regex 2026.7.19, pyyaml 6.0.3, markupsafe 3.0.3 |
| aiohttp family | aiohttp 3.14.3, yarl 1.24.5, propcache 0.5.2, frozenlist 1.8.0, multidict 6.7.1 |
| tree-sitter | tree-sitter 0.25.2, tree-sitter-language-pack 0.13.0, tree-sitter-c-sharp 0.23.1, tree-sitter-embedded-template 0.25.0, tree-sitter-yaml 0.7.2 |

Not included (optional): `hf-xet` (HuggingFace fast-transfer, Rust) — aider
does not import it; install with cargo if you need huge hub downloads.

## Platform

- Android aarch64, Python 3.14, Termux (F-Droid)

## Building from source / rebuilding the wheels

- **[UPDATE-2026.md](UPDATE-2026.md)** — the Aug 2026 recipe and every gotcha
  (libpython-link, rustc 1.98 ICE workarounds, `__ANDROID_MIN_SDK_VERSION__`).
- **[GUIDE.md](GUIDE.md)** — the original Feb 2026 full compilation guide
  (Python 3.12; kept as history and fix reference).
- The wheel builds themselves were done on-device (Termux build env) and
  cross-checked against the openviking build outputs; see the GUIDEs for the
  exact flags (libpython-link, rustc 1.98 ICE workarounds).

## Historical: February 2026 release (Python 3.12)

The original build (aider **0.86.2**, Python **3.12**, 5 archives) remains at
the [`v0.86.2-android-aarch64-py312`](https://github.com/skoll43/aider-chat-termux-wheels/releases/tag/v0.86.2-android-aarch64-py312)
release; it is superseded by the py314 path above.
