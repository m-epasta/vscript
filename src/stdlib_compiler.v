module main

// create_compiler_module returns the native MapValue for 'core:compiler'
fn create_compiler_module(mut vm VM) Value {
	mut exports := map[string]Value{}

	// get_diagnostics(source: string) -> []Diagnostic
	vm.define_native_in_map(mut exports, 'get_diagnostics', 1, fn (mut vm VM, args []Value) Value {
		source := args[0]
		if source is string {
			mut scanner := new_scanner(source as string)
			tokens := scanner.scan_tokens()
			mut parser := new_parser(tokens, false)
			// Try parsing to collect errors
			_ := parser.parse() or {
				// Errors are already collected in parser.errors
				[]Stmt{}
			}

			mut errs := []Value{}
			for e in parser.errors {
				mut err_obj := map[string]Value{}
				err_obj['line'] = Value(f64(e.line))
				err_obj['col'] = Value(f64(e.col))
				err_obj['message'] = Value(e.message)
				errs << Value(MapValue{
					items: err_obj
					gc:    vm.alloc_header(int(sizeof(MapValue)))
				})
			}
			return Value(ArrayValue{
				elements: errs
				gc:       vm.alloc_header(int(sizeof(ArrayValue)))
			})
		}
		return Value(ArrayValue{
			elements: []Value{}
			gc:       vm.alloc_header(int(sizeof(ArrayValue)))
		})
	})

	return Value(MapValue{
		items: exports
		gc:    vm.alloc_header(int(sizeof(MapValue)))
	})
}
