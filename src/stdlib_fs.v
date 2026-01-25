module main

import os

// create_fs_module returns the native MapValue for 'core:fs'
// create_fs_module returns the native MapValue for 'core:fs'
fn create_fs_module(mut vm VM) Value {
	mut exports := map[string]Value{}

	// read_file(path)
	vm.define_native_in_map(mut exports, 'read_file', 1, fn (mut vm VM, args []Value) Value {
		path := args[0]
		if path is string {
			content := os.read_file(path as string) or {
				return Value(EnumVariantValue{
					enum_name: 'Result'
					variant:   'err'
					values:    [Value(err.msg())]
				})
			}
			return Value(EnumVariantValue{
				enum_name: 'Result'
				variant:   'ok'
				values:    [Value(content)]
			})
		}
		return Value(EnumVariantValue{
			enum_name: 'Result'
			variant:   'err'
			values:    [Value('read_file expects a string path')]
		})
	})

	// write_file(path, content)
	vm.define_native_in_map(mut exports, 'write_file', 2, fn (mut vm VM, args []Value) Value {
		path := args[0]
		content := args[1]
		if path is string && content is string {
			os.write_file(path as string, content as string) or {
				return Value(EnumVariantValue{
					enum_name: 'Result'
					variant:   'err'
					values:    [Value('Failed to write file: ${err}')]
				})
			}
			return Value(EnumVariantValue{
				enum_name: 'Result'
				variant:   'ok'
				values:    [Value(true)]
			})
		}
		return Value(EnumVariantValue{
			enum_name: 'Result'
			variant:   'err'
			values:    [Value('write_file expects (path: string, content: string)')]
		})
	})

	// exists(path) -> bool
	vm.define_native_in_map(mut exports, 'exists', 1, fn (mut vm VM, args []Value) Value {
		path := args[0]
		if path is string {
			return Value(os.exists(path as string))
		}
		return Value(false)
	})

	// remove(path)
	vm.define_native_in_map(mut exports, 'remove', 1, fn (mut vm VM, args []Value) Value {
		path := args[0]
		if path is string {
			os.rm(path as string) or {
				return Value(EnumVariantValue{
					enum_name: 'Result'
					variant:   'err'
					values:    [Value('Failed to remove file: ${err}')]
				})
			}
			return Value(EnumVariantValue{
				enum_name: 'Result'
				variant:   'ok'
				values:    [Value(true)]
			})
		}
		return Value(EnumVariantValue{
			enum_name: 'Result'
			variant:   'err'
			values:    [Value('remove expects a string path')]
		})
	})

	return Value(MapValue{
		items: exports
	})
}

// Helper to define natives directly into a map (for modules)
fn (mut vm VM) define_native_in_map(mut m map[string]Value, name string, arity int, func NativeFn) {
	m[name] = Value(NativeFunctionValue{
		name:  name
		arity: arity
		func:  func
	})
}
