module main

import net.http

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

		// 2. Register Promise
		id := vm.next_promise_id
		vm.next_promise_id++
		state := &PromiseState{
			status: .pending
			value:  NilValue{}
		}
		vm.promises[id] = state

		// 3. Prepare Request Configuration
		mut req_method := http.Method.get
		if method_val := options['method'] {
			if method_val is string {
				req_method = match (method_val as string).to_upper() {
					'POST' { http.Method.post }
					'PUT' { http.Method.put }
					'DELETE' { http.Method.delete }
					'PATCH' { http.Method.patch }
					else { http.Method.get }
				}
			}
		}

		mut req_headers := http.new_header()
		if headers_val := options['headers'] {
			if headers_val is MapValue {
				for k, v in (headers_val as MapValue).items {
					req_headers.add_custom(k, value_to_string(v)) or {}
				}
			}
		}

		mut req_data := ''
		if body_val := options['body'] {
			req_data = value_to_string(body_val)
		}

		results_chan := vm.task_results

		// 4. Background Spawn
		spawn fn (id int, results_chan chan TaskResult, my_url string, my_method http.Method, my_headers http.Header, my_data string) {
			mut req := http.Request{
				url:    my_url
				method: my_method
				header: my_headers
				data:   my_data
			}

			resp := req.do() or {
				err_val := EnumVariantValue{
					enum_name: 'Result'
					variant:   'err'
					values:    [Value('HTTP request failed: ${err}')]
				}
				results_chan <- TaskResult{
					id:     id
					result: Value(err_val)
				}
				return
			}

			// Wrap response (note: we are in a thread, so Constructing MapValue is safe but VM pointers would not be)
			// But results_chan will deliver it to VM.
			mut resp_map := map[string]Value{}
			resp_map['status'] = Value(f64(resp.status_code))
			resp_map['body'] = Value(resp.body)
			resp_map['ok'] = Value(resp.status_code >= 200 && resp.status_code < 300)

			// helper: json() needs body. We pass body in context of NativeFunction
			// Wait! We can't call VM.define_native in a thread.
			// So we need to ensure the VM does it when processing the result.
			// Actually, let's keep it simple: the VM.poll_tasks will see this map and we can process it there.
			// BUT for now, let's just return the map. The caller can use json.parse().

			ok_val := EnumVariantValue{
				enum_name: 'Result'
				variant:   'ok'
				values:    [Value(MapValue{
					items: resp_map
				})]
			}
			results_chan <- TaskResult{
				id:     id
				result: Value(ok_val)
			}
		}(id, results_chan, url, req_method, req_headers, req_data)

		return Value(PromiseValue{
			id: id
		})
	}
	return Value(NilValue{})
}
