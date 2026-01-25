module main

import net.http

// create_http_module returns the native MapValue for 'core:http'
fn create_http_module(mut vm VM) Value {
	mut exports := map[string]Value{}

	// get(url) -> Result<string>
	vm.define_native_in_map(mut exports, 'get', 1, fn (mut vm VM, args []Value) Value {
		if args[0] is string {
			url := args[0] as string
			resp := http.get(url) or {
				return Value(EnumVariantValue{
					enum_name: 'Result'
					variant:   'err'
					values:    [Value('HTTP GET failed: ${err}')]
				})
			}
			return Value(EnumVariantValue{
				enum_name: 'Result'
				variant:   'ok'
				values:    [Value(resp.body)]
			})
		}
		return Value(EnumVariantValue{
			enum_name: 'Result'
			variant:   'err'
			values:    [Value('http.get expects a string URL')]
		})
	})

	// post(url, body) -> Result<string>
	vm.define_native_in_map(mut exports, 'post', 2, fn (mut vm VM, args []Value) Value {
		if args[0] is string && args[1] is string {
			url := args[0] as string
			body := args[1] as string
			resp := http.post(url, body) or {
				return Value(EnumVariantValue{
					enum_name: 'Result'
					variant:   'err'
					values:    [Value('HTTP POST failed: ${err}')]
				})
			}
			return Value(EnumVariantValue{
				enum_name: 'Result'
				variant:   'ok'
				values:    [Value(resp.body)]
			})
		}
		return Value(EnumVariantValue{
			enum_name: 'Result'
			variant:   'err'
			values:    [Value('http.post expects (url: string, body: string)')]
		})
	})

	return Value(MapValue{
		items: exports
	})
}
