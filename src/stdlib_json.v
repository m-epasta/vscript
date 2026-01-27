module main

// create_json_module returns the native MapValue for 'core:json'
fn create_json_module(mut vm VM) Value {
	mut exports := map[string]Value{}

	// parse(string) -> Result (uses existing native_json_decode logic)
	vm.define_native_in_map(mut exports, 'parse', 1, fn (mut vm VM, args []Value) Value {
		if args[0] is string {
			// Reuse json_to_value from native.v
			result := native_json_decode(mut vm, args)
			if result is NilValue {
				return Value(EnumVariantValue{
					enum_name: 'Result'
					variant:   'err'
					values:    [Value('Failed to parse JSON')]
					gc:        vm.alloc_header(int(int(sizeof(EnumVariantValue))))
				})
			}
			return Value(EnumVariantValue{
				enum_name: 'Result'
				variant:   'ok'
				values:    [result]
				gc:        vm.alloc_header(int(int(sizeof(EnumVariantValue))))
			})
		}
		return Value(EnumVariantValue{
			enum_name: 'Result'
			variant:   'err'
			values:    [Value('json.parse expects a string')]
			gc:        vm.alloc_header(int(int(sizeof(EnumVariantValue))))
		})
	})

	// stringify(value) -> string (uses existing value_to_json)
	vm.define_native_in_map(mut exports, 'stringify', 1, fn (mut vm VM, args []Value) Value {
		return Value(value_to_json(args[0]))
	})

	return Value(MapValue{
		items: exports
		gc:    vm.alloc_header(int(int(sizeof(EnumVariantValue))))
	})
}
