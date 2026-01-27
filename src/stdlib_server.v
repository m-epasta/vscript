module main

import net

fn create_http_server_module(mut vm VM) Value {
	mut exports := map[string]Value{}

	// bind(port) -> ServerObject
	vm.define_native_in_map(mut exports, 'bind', 1, fn (mut vm VM, args []Value) Value {
		port := int(args[0] as f64)

		mut listener := net.listen_tcp(.ip, ':${port}') or {
			return Value('Failed to start listener: ${err}')
		}

		l_addr := listener.addr() or { return Value('Failed to get address') }

		vm.net_manager.server_listener = &listener
		vm.net_manager.server_running = true

		// Start SINGLE background listener thread
		accepted_chan := vm.net_manager.server_accepted
		spawn run_server_listener(mut listener, accepted_chan)

		actual_port := l_addr.port() or { 0 }
		mut server_obj := map[string]Value{}
		server_obj['port'] = Value(f64(actual_port))
		vm.define_native_in_map(mut server_obj, 'accept', 0, native_server_accept)

		return Value(MapValue{
			items: server_obj
			gc:    vm.alloc_header(int(int(sizeof(EnumVariantValue))))
		})
	})

	return Value(MapValue{
		items: exports
		gc:    vm.alloc_header(int(int(sizeof(EnumVariantValue))))
	})
}

fn run_server_listener(mut listener net.TcpListener, accepted_chan chan &net.TcpConn) {
	for {
		mut conn := listener.accept() or { continue }
		accepted_chan <- conn
	}
}

fn native_server_accept(mut vm VM, args []Value) Value {
	promise_id := vm.next_promise_id
	vm.next_promise_id++

	vm.promises[promise_id] = &PromiseState{
		status: .pending
		value:  NilValue{}
		gc:     vm.alloc_header(int(int(sizeof(EnumVariantValue))))
	}

	vm.net_manager.server_accept_queue << promise_id

	return Value(PromiseValue{
		id: promise_id
	})
}
