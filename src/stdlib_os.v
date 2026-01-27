module main

import os

// create_os_module returns the native MapValue for 'core:os'
fn create_os_module(mut vm VM) Value {
	mut exports := map[string]Value{}

	// args -> []string
	mut args_vals := []Value{}
	for arg in os.args {
		args_vals << Value(arg)
	}
	exports['args'] = Value(ArrayValue{
		elements: args_vals
		gc:       vm.alloc_header(int(sizeof(ArrayValue)))
	})

	// stdin_read_line() -> string
	vm.define_native_in_map(mut exports, 'stdin_read_line', 0, fn (mut vm VM, args []Value) Value {
		line := os.get_line()
		return Value(line)
	})

	// stdin_read(n: number) -> string
	vm.define_native_in_map(mut exports, 'stdin_read', 1, fn (mut vm VM, args []Value) Value {
		if args[0] is f64 {
			n := int(args[0] as f64)
			if n <= 0 { return Value('') }
			mut buf := []u8{len: n}
			read_count := os.stdin().read(mut buf) or { 0 }
			return Value(buf[..read_count].bytestr())
		}
		return Value('')
	})

	// log(msg: string)
	vm.define_native_in_map(mut exports, 'log', 1, fn (mut vm VM, args []Value) Value {
		val := args[0]
		if val is string {
			eprintln(val as string)
		} else {
			eprintln(val.str())
		}
		return Value(NilValue{})
	})

	// stdout_write(s: string)
	vm.define_native_in_map(mut exports, 'stdout_write', 1, fn (mut vm VM, args []Value) Value {
		if args[0] is string {
			print(args[0] as string)
			unsafe {
				C.fflush(C.stdout)
			}
		}
		return Value(NilValue{})
	})

	// flush_stdout()
	vm.define_native_in_map(mut exports, 'flush_stdout', 0, fn (mut vm VM, args []Value) Value {
		unsafe {
			C.fflush(C.stdout)
		}
		return Value(NilValue{})
	})

	return Value(MapValue{
		items: exports
		gc:    vm.alloc_header(int(sizeof(MapValue)))
	})
}
