# aider-chat Termux Wheels

Pre-built Python wheels for **aider-chat 0.86.2** on Termux (Android aarch64, Python 3.12).

No compilation needed — hours of build time saved! This method provides the fast path for installation.

## Prerequisites

Before you begin, ensure you have the following installed in Termux. You can install them using `pkg install` for most of these, and `pip install` for `uv`.

```bash
pkg update && pkg upgrade -y
pkg install python unzip wget curl -y
pip install uv
```

*   `python` (version 3.12) - Installed via `pkg install python`
*   `pip` - Comes with `python`
*   `uv` - Installed via `pip install uv`
*   `unzip` - Installed via `pkg install unzip`
*   `wget` or `curl` - Installed via `pkg install wget` or `pkg install curl`

## Installation Steps

Follow these steps carefully to install `aider-chat` using the pre-built wheels.

**1. Create a Project Directory**

First, create a directory for your project and navigate into it:

```bash
mkdir ~/my-aider-project
cd ~/my-aider-project
```

**2. Create and Activate a Virtual Environment**

It is highly recommended to use a virtual environment to avoid conflicts with other Python packages.

```bash
python -m venv .venv
source .venv/bin/activate
```

**3. Download the Wheels**

Download all the `.zip` files from the [Releases page](https://github.com/skoll43/aider-chat-termux-wheels/releases) of this repository.

Create a `wheels` directory and download the files into it. For example, using `wget`:

```bash
mkdir wheels
cd wheels
wget https://github.com/skoll43/aider-chat-termux-wheels/releases/download/v0.86.2-android-aarch64-py312/aider-termux-scipy-py312.zip
wget https://github.com/skoll43/aider-chat-termux-wheels/releases/download/v0.86.2-android-aarch64-py312/aider-termux-numpy-py312.zip
wget https://github.com/skoll43/aider-chat-termux-wheels/releases/download/v0.86.2-android-aarch64-py312/aider-termux-rust-py312.zip
wget https://github.com/skoll43/aider-chat-termux-wheels/releases/download/v0.86.2-android-aarch64-py312/aider-termux-light-py312.zip
wget https://github.com/skoll43/aider-chat-termux-wheels/releases/download/v0.86.2-android-aarch64-py312/aider-termux-treesitter-py312.zip
cd ..
```

**4. Unzip the Wheels**

Unzip all the downloaded files into the `wheels` directory:

```bash
unzip wheels/*.zip -d wheels/
```

**5. Install the Wheels with `pip`**

Next, use `pip` to install the wheels you just downloaded.

We use `pip` here for its ability to directly install the `.whl` files without resolving dependencies yet. The `--no-deps` flag is crucial—it prevents `pip` from trying to download any dependencies, ensuring that only our pre-built wheels are placed into the environment.

```bash
pip install --no-deps wheels/*.whl
```

**6. Install aider-chat with `uv`**

Finally, use `uv` to install `aider-chat`. `uv`'s fast dependency resolver will scan the environment, see that the complex packages (like `numpy` and `scipy`) are already installed, and only download the remaining small dependencies.

This two-step process ensures the pre-compiled wheels are used while letting `uv` handle the final dependency resolution efficiently.

```bash
uv pip install aider-chat
```

After these steps, you should be able to run `aider-chat` from your terminal.

## Wheel Contents

| Archive | Packages |
|---------|----------|
| `aider-termux-scipy-py312.zip` | scipy 1.15.3 |
| `aider-termux-numpy-py312.zip` | numpy 1.26.4, tiktoken 0.12.0 |
| `aider-termux-rust-py312.zip` | pydantic-core, tokenizers, orjson, rpds-py, watchfiles, fastuuid, jiter |
| `aider-termux-light-py312.zip` | aiohttp, cffi, markupsafe, pillow, psutil, pyyaml, regex |
| `aider-termux-treesitter-py312.zip` | tree-sitter, tree-sitter-yaml, tree-sitter-c-sharp, tree-sitter-embedded-template, tree-sitter-language-pack |

## Platform

- Android aarch64
- Python 3.12
- Termux (F-Droid)

## Full Compilation Guide

See [GUIDE.md](GUIDE.md) for the complete compilation instructions, including all fixes and workarounds, that I followed to build these wheels.
