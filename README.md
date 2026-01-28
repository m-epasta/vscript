# vscript

A **lightning-fast**, JavaScript-compatible scripting language implemented in pure V. vscript features a high-performance bytecode VM, a JavaScript transpiler, and a robust standard library with functional programming primitives and decorators.

## Features

- ⚡ **Bytecode VM**: Zero-overhead execution with a custom stack-based virtual machine.
- ✅ **JS Transpiler**: Portable code generation for browser and Node.js environments.
- 🚀 **One-Binary**: Highly portable, zero-dependency implementation.

## Quick Start
### Build
```bash
v -o vscript src/
```

### Usage
- **Run script**: `./vscript tests/test_advanced.vs`
- **Execute inline**: `./vscript -e "print(1 + 2)"`
- **Transpile**: `./vscript --js tests/test_array.vs`

## Project Structure
- `src/`: Core implementation (Scanner, Parser, Compiler, VM, Transpiler).
- `tests/`: Feature verification scripts.
- `docs/`: In-depth documentation.
- `examples/`: Complex demonstration scripts (e.g., Fibonacci).

## Documentation
- [Standard Library Guide](docs/stdlib.md) — Examples for all built-in functions, decorators, and iterators.

## License
MIT
