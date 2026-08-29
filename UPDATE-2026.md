# aider-chat on Termux — 2026 Update (Python 3.14, git main)

> **Status: ✅ Working — aider 0.86.3.dev53+g5dc9490bb**
> Date: August 2026 · Python 3.14.6 · rustc 1.98.0
> Same device: Xiaomi Redmi 12 5G (aarch64, 6 cores, 8 GB swap)

This updates the [Feb 2026 GUIDE](../aider-chat-termux-wheels/GUIDE.md) with
what changed on modern Termux (python 3.14 / rustc 1.98) and the faster recipe.

## The big changes since Feb 2026

| Item | Feb 2026 guide | Now (Aug 2026) |
|---|---|---|
| Python | 3.12 | **3.14** (aider 0.86.2 needs `<3.13` — install **git main**, which allows `<3.15`) |
| numpy/scipy | built from source (~2 h) | **`pkg install python-numpy python-scipy`** — apt prebuilt, zero compilation |
| wheel retag | retag to `linux_aarch64` | obsolete — pip accepts `android_24_arm64_v8a` |
| `RUSTFLAGS -C target-cpu=native` | worked | **rustc 1.98 ICE** — remove |
| LTO (`CARGO_PROFILE_RELEASE_LTO`) | worked | **rustc 1.98 ICE** — remove/disable |
| Py* data symbols | (no issue on py3.12) | **must link `libpython3.14.so`** (see below) |
| tokenizers `pthread_cond_clockwait` | n/a | needs `-D__ANDROID_MIN_SDK_VERSION__=30` |

## The one critical new fix: link libpython

On py3.14/bionic, extensions referencing Python *data* symbols
(`PyExc_TypeError`, `PyModule_Type`, `_Py_NoneStruct`) fail to import unless
they link `libpython3.14.so`:

```
ImportError: dlopen failed: cannot locate symbol "PyExc_TypeError" ...
```

Fix in the build env:

```bash
export LDFLAGS="-L$PREFIX/lib -lpython3.14"
export RUSTFLAGS="-C link-arg=-L$PREFIX/lib -C link-arg=-lpython3.14"
```

## The 2026 recipe (much faster)

```bash
# 1. apt prebuilt heavy deps (no compilation!)
pkg install -y python-numpy python-scipy python-pillow python-psutil \
  python-tokenizers python-tiktoken python-cryptography python-lxml

# 2. venv with system-site-packages so it sees apt packages
uv venv --system-site-packages .venv
uv pip install --python .venv/bin/python pip setuptools wheel

# 3. wheels that still need source builds (from the openviking-termux-wheels release,
#    or build them: see openviking-termux-wheels/GUIDE.md for the exact flags)
pip install --no-deps ~/wheels/aider314/*.whl

# 4. pure-python deps — ALL from prebuilt wheels at aider's exact pins (no builds)
#    (see pure-deps-pinned.txt in this repo — generated from aider 0.86.3.dev53 metadata;
#     includes openai==2.28.0, fastapi, litellm==1.82.3, ...)

# 5. aider itself (git main — the version that supports Python 3.14)
pip install --no-deps "git+https://github.com/Aider-AI/aider.git"

# 6. runtime stragglers found by running it:
pip install --only-binary :all: json_logic
pip install --only-binary :all: "pydantic==2.12.5"
pip install --no-deps audioop-lts          # audioop for py3.14 (sdist build, tiny C)
printf 'from audioop import *\n' > .venv/lib/python3.14/site-packages/pyaudioop.py  # pydub shim
```

## Wheels that still need source builds (py314)

Only these — everything else is apt or pure-python wheels:

- pydantic-core 2.41.5, jiter 0.13.0, rpds-py 0.30.0, orjson 3.11.7, watchfiles 1.1.1 (Rust)
- tree-sitter 0.25.2, tree-sitter-language-pack 0.13.0, tree-sitter-c-sharp 0.23.1,
  tree-sitter-embedded-template 0.25.0, tree-sitter-yaml 0.7.2 (yaml needs scanner.c patch)
- cffi 2.0/2.1, regex, aiohttp family, markupsafe, pyyaml (same versions as Feb guide,
  rebuilt for cp314)
- audioop-lts 0.2.2 (tiny C)

## Verified

```
$ aider --version
aider 0.86.3.dev53+g5dc9490bb

$ aider --message "..."   # in a git repo
Repo-map: using 1024 tokens, auto refresh   # numpy/scipy/tokenizers/tree-sitter all working
```

Only step left for you: API keys (`~/.aider.model.settings.yml`, `~/.aider.model.metadata.json`,
`OPENAI_API_KEY`) — same as the Feb guide's Step 10.

---

## ☕ Support

If this saved you hours of compilation, consider buying me a coffee:

[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=flat-square&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/Lukl)

<https://www.buymeacoffee.com/Lukl>
---

## Related guide

The same build tricks (libpython-link, rustc 1.98 ICE workarounds,
`__ANDROID_MIN_SDK_VERSION__`, wheel-first builds) are documented in the
**[OpenViking Termux Wheels guide](https://github.com/skoll43/openviking-termux-wheels/blob/main/GUIDE.md)** —
including the 10-entry troubleshooting appendix.
