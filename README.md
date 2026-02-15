# aider-chat Termux Wheels

Pre-built Python wheels for **aider-chat 0.86.2** on Termux (Android aarch64, Python 3.12).

No compilation needed — hours of build time saved!

## Install

Download all zip files from the [latest release](https://github.com/skoll43/aider-chat-termux-wheels/releases), extract into a `~/wheels` folder, then:

\`\`\`bash
pip install --no-deps ~/wheels/*.whl
uv pip install --python .venv/bin/python aider-chat
\`\`\`

## Wheel Contents

| Archive | Packages |
|---------|----------|
| \`aider-termux-scipy-py312.zip\` | scipy 1.15.3 |
| \`aider-termux-numpy-py312.zip\` | numpy 1.26.4, tiktoken 0.12.0 |
| \`aider-termux-rust-py312.zip\` | pydantic-core, tokenizers, orjson, rpds-py, watchfiles, fastuuid, jiter |
| \`aider-termux-light-py312.zip\` | aiohttp, cffi, markupsafe, pillow, psutil, pyyaml, regex |
| \`aider-termux-treesitter-py312.zip\` | tree-sitter, tree-sitter-yaml, tree-sitter-c-sharp, tree-sitter-embedded-template, tree-sitter-language-pack |

## Platform

- Android aarch64
- Python 3.12
- Termux (F-Droid)

## Full Installation Guide

See [GUIDE.md](GUIDE.md) for the complete installation process including all fixes and workarounds.
