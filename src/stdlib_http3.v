module main

// fetch(url, options) -> Promise<Result<Response>>
fn create_http3_module(mut vm VM) Value {
	mut exports := map[string]Value{}

	vm.define_native_in_map(mut exports, 'fetch', 2, fn (mut vm VM, args []Value) Value {
		if args[0] is string {
			url := args[0] as string

			id := vm.next_promise_id
			vm.next_promise_id++

			// Transfer state handle
			mut state := &PromiseState{
				status: .pending
				value:  NilValue{}
			}
			vm.promises[id] = state

			// Setup Easy Handle
			handle := C.curl_easy_init()
			if handle == 0 {
				state.value = Value('Failed to init curl')
				state.status = .resolved
				return Value(PromiseValue{
					id: id
				})
			}

			C.curl_easy_setopt(handle, curlopt_url, url.str)
			// Force HTTP/3
			C.curl_easy_setopt(handle, curlopt_http_version, curl_http_version_3)
			C.curl_easy_setopt(handle, curlopt_pipewait, voidptr(curl_pipewait))

			// Context on heap for body gathering and callback context
			mut body_ctx := &TransferContext{
				body: ''
			}

			mut cb_ctx := &CurlCallbackContext{
				vm:          &vm
				easy_handle: handle
			}

			C.curl_easy_setopt(handle, curlopt_writefunction, write_callback)
			C.curl_easy_setopt(handle, curlopt_writedata, cb_ctx)

			// Register with VM Multi Handle
			vm.net_manager.active_transfers[handle] = id
			vm.net_manager.transfer_bodies[handle] = &body_ctx.body

			C.curl_multi_add_handle(vm.net_manager.curl_multi_handle, handle)

			return Value(PromiseValue{
				id: id
			})
		}
		return Value(NilValue{})
	})

	return Value(MapValue{
		items: exports
	})
}
