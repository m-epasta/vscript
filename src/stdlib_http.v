module main

// request(url, options) -> Promise<Result<Response>>
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
		mut state := &PromiseState{
			status: .pending
			value:  NilValue{}
		}
		vm.promises[id] = state

		// 3. Setup Easy Handle
		handle := C.curl_easy_init()
		if handle == 0 {
			state.value = Value('Failed to init curl')
			state.status = .resolved
			return Value(PromiseValue{
				id: id
			})
		}

		C.curl_easy_setopt(handle, curlopt_url, url.str)

		// Elite Feature: Use the global share handle for pooling and persistent cookies
		C.curl_easy_setopt(handle, curlopt_share, vm.curl_share_handle)
		// Enable cookie engine
		C.curl_easy_setopt(handle, 10031, c'') // CURLOPT_COOKIEFILE = "" enables engine in memory

		// Map method
		if method_val := options['method'] {
			if method_val is string {
				m_str := (method_val as string).to_upper()
				if m_str == 'POST' {
					C.curl_easy_setopt(handle, 10047, voidptr(1)) // CURLOPT_POST
				}
			}
		}

		if body_val := options['body'] {
			body_str := value_to_string(body_val)
			C.curl_easy_setopt(handle, 10015, body_str.str) // CURLOPT_POSTFIELDS
		}

		// Options: stream
		is_streaming := if s := options['stream'] {
			if s is bool { s as bool } else { false }
		} else {
			false
		}

		// Context on heap for body gathering and callback context
		mut body_ctx := &TransferContext{
			body: ''
		}

		mut cb_ctx := &CurlCallbackContext{
			vm:          vm
			easy_handle: handle
		}

		C.curl_easy_setopt(handle, curlopt_writefunction, write_callback)
		C.curl_easy_setopt(handle, curlopt_writedata, cb_ctx)
		C.curl_easy_setopt(handle, curlopt_headerfunction, header_callback)

		// Register with VM
		vm.active_transfers[handle] = id
		if is_streaming {
			vm.stream_queues[handle] = chan string{cap: 100}
		} else {
			vm.transfer_bodies[handle] = &body_ctx.body
		}

		C.curl_multi_add_handle(vm.curl_multi_handle, handle)

		return Value(PromiseValue{
			id: id
		})
	}
	return Value(NilValue{})
}

fn create_http_module(mut vm VM) Value {
	mut exports := map[string]Value{}

	vm.define_native_in_map(mut exports, 'request', 2, fn (mut vm VM, args []Value) Value {
		return execute_http_request(mut vm, args[0], args[1])
	})

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

	// Session() -> Object
	vm.define_native_in_map(mut exports, 'Session', 0, fn (mut vm VM, args []Value) Value {
		mut sess := map[string]Value{}

		// For now, Session just uses the global share handle (VM scope)
		// but providing the same API as top-level http for discovery
		vm.define_native_in_map(mut sess, 'get', 1, fn (mut v VM, a []Value) Value {
			return execute_http_request(mut v, a[0], Value(MapValue{
				items: {
					'method': Value('GET')
				}
			}))
		})

		vm.define_native_in_map(mut sess, 'post', 2, fn (mut v VM, a []Value) Value {
			return execute_http_request(mut v, a[0], Value(MapValue{
				items: {
					'method': Value('POST')
					'body':   a[1]
				}
			}))
		})

		return Value(MapValue{ items: sess })
	})

	return Value(MapValue{
		items: exports
	})
}
