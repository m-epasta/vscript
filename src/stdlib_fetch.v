module main

// fetch(url, options) -> Promise<Response>
fn create_fetch_module(mut vm VM) Value {
	mut exports := map[string]Value{}

	// Global fetch function
	vm.define_native_in_map(mut exports, 'fetch', 2, fn (mut vm VM, args []Value) Value {
		// Re-use logic from http.request for now, but expose it as fetch
		// We can eventually replace http.v with this or make http.v use this
		return execute_http_request(mut vm, args[0], args[1])
	})

	return Value(MapValue{
		items: exports
		gc:    vm.alloc_header(int(int(sizeof(EnumVariantValue))))
	})
}

// Implement methods on Response object via decorators or direct map functions in net_manager
// For now, let's ensure execute_http_request uses net_manager and returns the augmented map
