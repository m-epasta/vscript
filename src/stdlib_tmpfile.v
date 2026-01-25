module main

import os
import rand

// create_tmpfile_module returns the native MapValue for 'core:tmpfile'
fn create_tmpfile_module(mut vm VM) Value {
	mut exports := map[string]Value{}

	// random_path() -> string
	vm.define_native_in_map(mut exports, 'random_path', 0, fn (mut vm VM, args []Value) Value {
		temp_dir := os.temp_dir()
		// Generate random suffix
		suffix := rand.intn(1000000) or { 64 }
		filename := 'vscript_test_${suffix}.txt'
		path := os.join_path(temp_dir, filename)
		return Value(path)
	})

	return Value(MapValue{
		items: exports
	})
}
