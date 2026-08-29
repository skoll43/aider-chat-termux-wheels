# aider-chat Termux Wheels

Pre-built Android wheels for **aider-chat 0.86.3.dev53 (git main)** on Termux
(Android aarch64, **Python 3.14**).

> **Status: ✅ Working (August 2026)** — on-device verified:
> `aider 0.86.3.dev53+g5dc9490bb`, Python 3.14.6, rustc 1.98.0.

The heavy packages that have **no Android wheels** are covered by this release
(zero compilation on the phone): apt provides `numpy`/`scipy`/`tokenizers`/
`tiktoken`/`cryptography`/`pillow`/`psutil`/`lxml` prebuilt, and this repo
provides the one wheel bundle for the Rust/C extensions.

> **📌 Full recipe & gotchas:** see **[UPDATE-2026.md](UPDATE-2026.md)** — the
> complete August 2026 install walkthrough (why Python 3.14, the
> libpython-link fix, exact pins, runtime stragglers).
> **[GUIDE.md](GUIDE.md)** remains the full compilation guide (Feb 2026,
> Python 3.12 build history; every fix that also applies to 3.14 is there).

## Prerequisites

```bash
pkg update && pkg upgrade -y
pkg install python unzip wget curl -y
pip install uv
```

*   `python` (3.14) — via `pkg install python`
*   `uv` — via `pip install uv`
*   `unzip`, `wget`/`curl` — via `pkg`

## Installation (2026 — recommended)

**1. Install the apt-prebuilt heavy deps (no compilation):**

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

**3. Download the single wheel bundle and install it:**

```bash
wget https://github.com/skoll43/aider-chat-termux-wheels/releases/download/v0.86.3.dev53-py314/aider-termux-py314-wheels.zip
unzip aider-termux-py314-wheels.zip -d wheels
pip install --no-deps wheels/*.whl
```

**4. Install aider itself (git main — the version that supports Python 3.14):**

```bash
pip install --no-deps "git+https://github.com/Aider-AI/aider.git"
```

**5. Runtime stragglers found by running it:**

```bash
pip install --only-binary :all: json_logic
pip install --only-binary :all: "pydantic==2.12.5"
pip install --no-deps audioop-lts          # audioop for py3.14 (tiny C sdist)
printf 'from audioop import *\n' > .venv/lib/python3.14/site-packages/pyaudioop.py  # pydub shim
```

**6. Verify:**

```bash
aider --version   # aider 0.86.3.dev53+g5dc9490bb
```

Only step left: API keys (`~/.aider.model.settings.yml`,
`~/.aider.model.metadata.json`, `OPENAI_API_KEY`) — same as GUIDE.md Step 10.

## Wheel Contents (`aider-termux-py314-wheels.zip`)

| Group | Packages |
|-------|----------|
| Rust | pydantic-core 2.41.5, jiter 0.13.0, rpds-py 0.30.0, orjson 3.11.7, watchfiles 1.1.1, fastuuid 0.14.0 |
| tree-sitter | tree-sitter 0.25.2, tree-sitter-language-pack 0.13.0, tree-sitter-c-sharp 0.23.1, tree-sitter-embedded-template 0.25.0, tree-sitter-yaml 0.7.2 |
| C / pure | pyyaml 6.0.3, markupsafe 3.0.3, frozenlist 1.8.0, multidict 6.7.1 |

## Platform

- Android aarch64
- Python 3.14
- Termux (F-Droid)

## Historical: February 2026 release (Python 3.12)

The original build (aider **0.86.2**, Python **3.12**, 5 wheel archives +
source-built scipy) is still available at the
[`v0.86.2-android-aarch64-py312`](https://github.com/skoll43/aider-chat-termux-wheels/releases/tag/v0.86.2-android-aarch64-py312)
release. It is superseded by the py314 path above; its compilation procedure
is documented in [GUIDE.md](GUIDE.md).

## Full Compilation Guide

See [GUIDE.md](GUIDE.md) for the complete compilation instructions, including
all fixes and workarounds (rustc 1.98 ICE workarounds, libpython-link,
`__ANDROID_MIN_SDK_VERSION__`, tree-sitter scanner patches), and
[UPDATE-2026.md](UPDATE-2026.md) for how the recipe changed on Python 3.14.
