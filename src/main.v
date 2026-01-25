// vscript - A JavaScript-compatible scripting language
// Main entry point
module main

import os

fn main() {
	args := os.args[1..]

	if args.len == 0 {
		println('vscript v0.2.0 - JavaScript-compatible scripting language')
		println('Usage:')
		println('  vscript <file.vs>           Run with VM (bytecode)')
		println('  vscript --transpile <file>  Transpile to .js file')
		println('  vscript --js <file>         Transpile and show JS')
		println('  vscript --scan <file>       Show tokens (debug)')
		return
	}

	match args[0] {
		'--transpile', '-t' {
			if args.len < 2 {
				eprintln('Error: Please specify a file to transpile')
				exit(1)
			}
			transpile_to_file(args[1])
		}
		'--js' {
			if args.len < 2 {
				eprintln('Error: Please specify a file')
				exit(1)
			}
			transpile_and_show(args[1])
		}
		'--scan' {
			if args.len < 2 {
				eprintln('Error: Please specify a file to scan')
				exit(1)
			}
			scan_file(args[1])
		}
		'-e' {
			if args.len < 2 {
				eprintln('Error: Please specify code to run')
				exit(1)
			}
			run_string(args[1])
		}
		else {
			// Default: Run with VM
			run_file(args[0])
		}
	}
}

fn run_file(path string) {
	source := os.read_file(path) or {
		eprintln('Error: Could not read file "${path}"')
		exit(74)
	}
	run_string(source)
}

fn run_string(source string) {
	mut vm := new_vm()
	result := vm.interpret(source)

	match result {
		.compile_error {
			eprintln('Compilation error')
			exit(65)
		}
		.runtime_error {
			eprintln('Runtime error')
			exit(70)
		}
		.ok {}
	}
}

fn transpile_and_show(path string) {
	source := os.read_file(path) or {
		eprintln('Error: Could not read file "${path}"')
		exit(74)
	}

	// Scan
	mut scanner := new_scanner(source)
	tokens := scanner.scan_tokens()

	// Parse
	mut parser := new_parser(tokens)
	stmts := parser.parse() or {
		eprintln('Parse error: ${err}')
		exit(65)
	}

	// Transpile
	mut transpiler := new_transpiler()
	js_code := transpiler.transpile_stmts(stmts)

	println('// Transpiled from ${path}')
	println(js_code)
}

fn transpile_to_file(path string) {
	source := os.read_file(path) or {
		eprintln('Error: Could not read file "${path}"')
		exit(74)
	}

	// Scan
	mut scanner := new_scanner(source)
	tokens := scanner.scan_tokens()

	// Parse
	mut parser := new_parser(tokens)
	stmts := parser.parse() or {
		eprintln('Parse error: ${err}')
		exit(65)
	}

	// Transpile
	mut transpiler := new_transpiler()
	js_code := transpiler.transpile_stmts(stmts)

	// Write to .js file
	output_path := path.replace('.vs', '.js')
	os.write_file(output_path, js_code) or {
		eprintln('Error: Could not write file "${output_path}"')
		exit(74)
	}

	println('✓ Transpiled ${path} -> ${output_path}')
}

fn scan_file(path string) {
	source := os.read_file(path) or {
		eprintln('Error: Could not read file "${path}"')
		exit(74)
	}

	mut scanner := new_scanner(source)
	tokens := scanner.scan_tokens()

	println('=== Tokens from ${path} ===')
	for token in tokens {
		if token.type_ != .eof {
			println(token.str())
		}
	}
}
