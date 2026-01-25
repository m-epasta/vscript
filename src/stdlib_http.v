module main

import net.http

// create_http_module returns the native MapValue for 'core:http'
// create_http_module returns the native MapValue for 'core:http'
fn create_http_module(mut vm VM) Value {
	mut exports := map[string]Value{}

	// request(url, options) -> Promise<Result<Response>>
	vm.define_native_in_map(mut exports, 'request', 2, fn (mut vm VM, args []Value) Value {
		return execute_http_request(mut vm, args[0], args[1])
	})

	// Helpers
	vm.define_native_in_map(mut exports, 'get', 1, fn (mut vm VM, args []Value) Value {
		return execute_http_request(mut vm, args[0], Value(MapValue{
			items: {
				'method': Value('GET')
			}
		}))
	})

	vm.define_native_in_map(mut exports, 'post', 2, fn (mut vm VM, args []Value) Value {
		return execute_http_request(mut vm, args[0], Value(MapValue{
			items: {
				'method': Value('POST')
				'body':   args[1]
			}
		}))
	})

	return Value(MapValue{
		items: exports
	})
}

fn execute_http_request(mut vm VM, url_val Value, options_val Value) Value {
	if url_val is string {
		mut url := url_val as string
		mut options := map[string]Value{}
		if options_val is MapValue {
			options = (options_val as MapValue).items
		}

		// 1. Handle Params
		if params_val := options['params'] {
			if params_val is MapValue {
				mut query := []string{}
				for k, v in (params_val as MapValue).items {
					val_str := value_to_string(v)
					query << '${k}=${val_str}'
				}
				if query.len > 0 {
					separator := if url.contains('?') { '&' } else { '?' }
					url += separator + query.join('&')
				}
			}
		}

		// 2. Prepare Request
		mut req := http.Request{
			url:    url
			method: http.Method.get
		}

		if method_val := options['method'] {
			if method_val is string {
				req.method = match (method_val as string).to_upper() {
					'POST' { http.Method.post }
					'PUT' { http.Method.put }
					'DELETE' { http.Method.delete }
					'PATCH' { http.Method.patch }
					else { http.Method.get }
				}
			}
		}

		if headers_val := options['headers'] {
			if headers_val is MapValue {
				for k, v in (headers_val as MapValue).items {
					// Use custom header for string keys
					req.header.add_custom(k, value_to_string(v)) or {}
				}
			}
		}

		if body_val := options['body'] {
			req.data = value_to_string(body_val)
		}

		// 3. Execute
		resp := req.do() or {
			result := EnumVariantValue{
				enum_name: 'Result'
				variant:   'err'
				values:    [Value('HTTP request failed: ${err}')]
			}
			return Value(PromiseValue{
				status: .resolved
				value:  Value(result)
			})
		}

		// 4. Response Map
		mut resp_map := map[string]Value{}
		resp_map['status'] = Value(f64(resp.status_code))
		resp_map['body'] = Value(resp.body)
		resp_map['ok'] = Value(resp.status_code >= 200 && resp.status_code < 300)

		// helper: json() - Placeholder for now as V natives can't easily capture
		vm.define_native_in_map(mut resp_map, 'json', 0, fn (mut v VM, a []Value) Value {
			return Value(NilValue{})
		})

		result := EnumVariantValue{
			enum_name: 'Result'
			variant:   'ok'
			values:    [Value(MapValue{
				items: resp_map
			})]
		}
		return Value(PromiseValue{
			status: .resolved
			value:  Value(result)
		})
	}
	return Value(NilValue{})
}
