TERMUX_PKG_HOMEPAGE=https://github.com/Aider-AI/aider
TERMUX_PKG_DESCRIPTION="AI pair programming in your terminal"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@skoll43"
TERMUX_PKG_VERSION=0.86.2
TERMUX_PKG_SRCURL=https://files.pythonhosted.org/packages/source/a/aider-chat/aider_chat-${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=SKIP_CHECKSUM
TERMUX_PKG_DEPENDS="python, clang, rust, flang, mold, libandroid-spawn, libjpeg-turbo, libpng, libwebp, libtiff, zlib, openssl, libffi"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_make_install() {
  # Required environment for Android builds
  export ANDROID_API_LEVEL=24
  export UV_LINK_MODE=copy
  export CC="clang"
  export CXX="clang++"
  export LDFLAGS="-L$TERMUX_PREFIX/lib -fuse-ld=$(which mold)"
  export CFLAGS="-I$TERMUX_PREFIX/include -O2"
  export CXXFLAGS="-I$TERMUX_PREFIX/include -O2"
  export RUSTFLAGS="-C target-cpu=native"
  export CARGO_BUILD_JOBS=4
  export FC=flang
  export F77=flang

  # Fix missing tree-sitter headers
  mkdir -p $TERMUX_PREFIX/include/tree_sitter
  YAML_SRC=$(find ~/.cache/uv -path "*tree-sitter-yaml*" -name "parser.h" 2>/dev/null | head -1 | xargs dirname)
  cp $YAML_SRC/parser.h $TERMUX_PREFIX/include/tree_sitter/
  cp $YAML_SRC/alloc.h $TERMUX_PREFIX/include/tree_sitter/
  cp $YAML_SRC/array.h $TERMUX_PREFIX/include/tree_sitter/
  echo 'typedef struct { uint16_t index; uint16_t length; } TSFieldMapSlice;' >> $TERMUX_PREFIX/include/tree_sitter/parser.h
  echo '#define version abi_version' >> $TERMUX_PREFIX/include/tree_sitter/parser.h

  # Fix missing tree-sitter-yaml scanner
  YAML_HASH=$(ls ~/.cache/uv/sdists-v9/pypi/tree-sitter-yaml/0.7.2/ 2>/dev/null | head -1)
  if [ -n "$YAML_HASH" ]; then
    YAML_SRC_DIR=~/.cache/uv/sdists-v9/pypi/tree-sitter-yaml/0.7.2/$YAML_HASH/src/src
    curl -L "https://raw.githubusercontent.com/tree-sitter-grammars/tree-sitter-yaml/master/src/scanner.c" -o $YAML_SRC_DIR/scanner.c
    curl -L "https://raw.githubusercontent.com/tree-sitter-grammars/tree-sitter-yaml/master/src/schema.core.c" -o $YAML_SRC_DIR/schema.core.c
  fi

  # Install with uv
  pip install uv
  uv venv $TERMUX_PREFIX/lib/python-aider/.venv
  uv pip install --python $TERMUX_PREFIX/lib/python-aider/.venv/bin/python aider-chat==${TERMUX_PKG_VERSION}

  # Fix tree-sitter-yaml binding
  SYSTEM_BINDING=$(find $TERMUX_PREFIX/lib/python3.12/site-packages/tree_sitter_yaml -name "_binding.abi3.so" 2>/dev/null | head -1)
  VENV_BINDING=$TERMUX_PREFIX/lib/python-aider/.venv/lib/python3.12/site-packages/tree_sitter_yaml/_binding.abi3.so
  [ -f "$SYSTEM_BINDING" ] && cp $SYSTEM_BINDING $VENV_BINDING

  # Install launcher
  mkdir -p $TERMUX_PREFIX/bin
  cat > $TERMUX_PREFIX/bin/aider << 'LAUNCHER'
#!/data/data/com.termux/files/usr/bin/bash
source /data/data/com.termux/files/usr/lib/python-aider/.venv/bin/activate
exec aider "$@"
LAUNCHER
  chmod +x $TERMUX_PREFIX/bin/aider
}
