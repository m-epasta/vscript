module main

import os

struct Stats {
mut:
	passed int
	failed int
}

fn main() {
	println('vscript Test Runner')
	println('v 0.1.0')
	println('-------------------')

	println('Building vscript...')
	res := os.execute('v -o vscript src/')
	if res.exit_code != 0 {
		eprintln('Build failed:\n${res.output}')
		exit(1)
	}

	mut stats := Stats{}
	walk_and_test('tests', mut stats)

	println('-------------------')
	println('Summary: ${stats.passed} passed, ${stats.failed} failed.')

	if stats.failed > 0 {
		exit(1)
	}
}

fn walk_and_test(dir string, mut stats Stats) {
	files := os.ls(dir) or { return }
	for file in files {
		path := os.join_path(dir, file)
		if os.is_dir(path) {
			walk_and_test(path, mut stats)
		} else if path.ends_with('.vs') {
			run_test(path, mut stats)
		}
	}
}

fn run_test(path string, mut stats Stats) {
	print('Running ${path} ... ')
	cmd := './vscript test ${path}'
	test_res := os.execute(cmd)

	if test_res.exit_code == 0 {
		println('OK')
		stats.passed++
	} else {
		println('FAIL')
		// println(test_res.output) // Optional: show failure output
		// For framework tests, maybe silence unless verbose?
		// But failure reason is important.
		println(test_res.output)
		stats.failed++
	}
}
