# Termux Package Recipe for aider-chat

This is a work-in-progress recipe for submitting aider-chat to the official
[termux-packages](https://github.com/termux/termux-packages) repository.

## Status

- [x] Basic build.sh structure
- [x] Environment flags for Android aarch64
- [x] tree-sitter header fixes
- [x] tree-sitter-yaml scanner fix
- [ ] Docker-based termux build system integration
- [ ] SHA256 checksum verification
- [ ] Automated testing

## Known Build Issues

### 1. tree-sitter-yaml missing scanner.c
The PyPI sdist for tree-sitter-yaml 0.7.2 is missing scanner.c.
Reported upstream: https://github.com/tree-sitter-grammars/tree-sitter-yaml/issues

Workaround: download scanner.c and schema.core.c from GitHub during build.

### 2. Pinned numpy/scipy versions
aider-chat 0.86.2 requires exactly:
- numpy==1.26.4
- scipy==1.15.3

### 3. Platform wheel tags
Rust packages build with android-tagged wheels that must be retagged to
linux_aarch64 for pip compatibility on Termux.

### 4. OOM kills during parallel builds
Build Rust packages one at a time with CARGO_BUILD_JOBS=4 and a 6GB swapfile.

## Full Guide

See the complete installation guide with all fixes and workarounds:
[GUIDE.md](../GUIDE.md)

## Contributing

If you get this recipe working in the termux Docker build system, please
open a PR at https://github.com/termux/termux-packages
