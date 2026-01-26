module main

fn create_ws_module(mut vm VM) Value {
	mut exports := map[string]Value{}

	// connect(url) -> Promise<SocketValue>
	vm.define_native_in_map(mut exports, 'connect', 1, fn (mut vm VM, args []Value) Value {
		if args[0] is string {
			url := args[0] as string

			id := vm.next_promise_id
			vm.next_promise_id++

			mut state := &PromiseState{ status: .pending, value: NilValue{} }
			vm.promises[id] = state

			handle := C.curl_easy_init()
			if handle == 0 {
				state.value = Value('Failed to init curl for WS')
				state.status = .resolved
				return Value(PromiseValue{
					id: id
				})
			}

			C.curl_easy_setopt(handle, curlopt_url, url.str)

			// Context for handshake detection
			mut cb_ctx := &CurlCallbackContext{
				vm:          &vm
				easy_handle: handle
			}

			C.curl_easy_setopt(handle, curlopt_headerfunction, header_callback)
			C.curl_easy_setopt(handle, curlopt_writedata, cb_ctx)

			// WebSocket mode: we handle frames manually in poll loop.
			// We MUST set a write callback even if empty to prevent libcurl from writing to stdout
			C.curl_easy_setopt(handle, curlopt_writefunction, fn (data &char, size usize, nmemb usize, userdata voidptr) usize {
				return size * nmemb
			})

			vm.net_manager.active_transfers[handle] = id

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
