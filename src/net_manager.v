module main

import net
import x.json2

struct NetworkManager {
mut:
	curl_multi_handle   &C.CURLM
	active_transfers    map[voidptr]int         // easy_handle -> promise_id
	transfer_bodies     map[voidptr]&string     // easy_handle -> buffer pointer (on heap)
	stream_queues       map[voidptr]chan string // easy_handle -> chunk channel
	stream_headers_done map[voidptr]bool        // easy_handle -> bool
	ws_queues           map[voidptr]chan string // easy_handle -> msg channel
	response_headers    map[voidptr]map[string]string
	curl_share_handle   &C.CURLSH

	// Server state
	server_running      bool
	server_listener     voidptr
	server_accepted     chan &net.TcpConn
	server_accept_queue []int // promise_ids waiting for a connection
}

fn new_network_manager() NetworkManager {
	unsafe {
		mut nm := NetworkManager{
			curl_multi_handle:   C.curl_multi_init()
			active_transfers:    map[voidptr]int{}
			transfer_bodies:     map[voidptr]&string{}
			stream_queues:       map[voidptr]chan string{}
			stream_headers_done: map[voidptr]bool{}
			ws_queues:           map[voidptr]chan string{}
			response_headers:    map[voidptr]map[string]string{}
			curl_share_handle:   C.curl_share_init()
			server_running:      false
			server_listener:     nil
			server_accepted:     chan &net.TcpConn{cap: 64}
			server_accept_queue: []int{}
		}

		// Configure global share handle
		C.curl_share_setopt(nm.curl_share_handle, curlshopt_share, voidptr(curl_lock_data_cookie))
		C.curl_share_setopt(nm.curl_share_handle, curlshopt_share, voidptr(curl_lock_data_dns))
		C.curl_share_setopt(nm.curl_share_handle, curlshopt_share, voidptr(curl_lock_data_ssl_session))
		C.curl_share_setopt(nm.curl_share_handle, curlshopt_share, voidptr(curl_lock_data_connect))

		return nm
	}
}

fn (mut nm NetworkManager) poll(mut vm VM) {
	if nm.active_transfers.len > 0 {
		mut still_running := 0
		C.curl_multi_poll(nm.curl_multi_handle, 0, 0, 1, &still_running)
		C.curl_multi_perform(nm.curl_multi_handle, &still_running)

		// Phase 1: Early Resolution (Streaming or WebSocket Handshake)
		for handle, id in nm.active_transfers {
			if nm.stream_headers_done[handle] {
				if mut state := vm.promises[id] {
					if state.status == .pending {
						mut status := 0
						C.curl_easy_getinfo(handle, 2097154, &status)

						// Detect WebSocket via status 101 or protocol
						if status == 101 {
							msg_chan := chan string{cap: 100}
							nm.ws_queues[handle] = msg_chan

							sock_obj := SocketValue{
								handle:   handle
								messages: msg_chan
								gc:       vm.alloc_header(int(sizeof(MapValue)))
							}

							mut sock_methods := map[string]Value{}
							vm.define_native_in_map_with_context(mut sock_methods, 'send',
								1, [Value(sock_obj)], native_socket_send)
							vm.define_native_in_map_with_context(mut sock_methods, 'recv',
								0, [Value(sock_obj)], native_socket_recv)
							vm.define_native_in_map_with_context(mut sock_methods, 'close',
								0, [Value(sock_obj)], native_socket_close)

							state.value = Value(EnumVariantValue{
								enum_name: 'Result'
								variant:   'ok'
								values:    [
									Value(MapValue{
										items: sock_methods
										gc:    vm.alloc_header(int(sizeof(MapValue)))
									}),
								]
								gc:        vm.alloc_header(int(sizeof(MapValue)))
							})
							state.status = .resolved
							continue
						}

						if q := nm.stream_queues[handle] {
							mut resp_map := map[string]Value{}
							resp_map['status'] = Value(f64(status))
							resp_map['ok'] = Value(status >= 200 && status < 300)
							resp_map['protocol'] = Value('Unified (Streaming)')

							stream_obj := StreamValue{
								chunks: q
								gc:     vm.alloc_header(int(sizeof(MapValue)))
							}

							mut stream_res := map[string]Value{}
							vm.define_native_in_map_with_context(mut stream_res, 'read',
								0, [Value(stream_obj)], native_stream_read)
							vm.define_native_in_map_with_context(mut stream_res, 'is_closed',
								0, [Value(stream_obj)], native_stream_is_closed)

							resp_map['body'] = Value(MapValue{
								items: stream_res
								gc:    vm.alloc_header(int(sizeof(MapValue)))
							})

							state.value = Value(EnumVariantValue{
								enum_name: 'Result'
								variant:   'ok'
								values:    [
									Value(MapValue{
										items: resp_map
										gc:    vm.alloc_header(int(sizeof(MapValue)))
									}),
								]
								gc:        vm.alloc_header(int(sizeof(MapValue)))
							})
							state.status = .resolved
						}
					}
				}
			}
		}

		// Phase 1.5: Receive WebSocket Frames
		for handle, q in nm.ws_queues {
			// Attempt to receive frames
			mut buffer := []u8{len: 4096}
			mut received := usize(0)
			mut meta := &C.curl_ws_frame(unsafe { nil })

			for {
				res := unsafe { C.curl_ws_recv(handle, buffer.data, 4096, &received, &meta) }
				if res != 0 {
					break
				}
				if received == 0 {
					break
				}

				// Process frame
				unsafe {
					chunk := (&char(buffer.data)).vstring_with_len(int(received))
					q <- chunk
				}
				// If no more data available immediately, stop internal loop
				if unsafe { meta != 0 && meta.bytesleft == 0 } {
					break
				}
			}
		}

		// Phase 2: Final Resolution
		mut msgs_in_queue := 0
		for {
			msg := C.curl_multi_info_read(nm.curl_multi_handle, &msgs_in_queue)
			if msg == 0 {
				break
			}

			if msg.msg == curlmsg_done {
				easy_handle := msg.easy_handle
				id := nm.active_transfers[easy_handle] or { continue }

				if mut state := vm.promises[id] {
					if state.status == .pending {
						mut status := 0
						C.curl_easy_getinfo(easy_handle, 2097154, &status)

						body_ptr := nm.transfer_bodies[easy_handle] or { continue }
						body := *body_ptr

						mut resp_map := map[string]Value{}
						resp_map['status'] = Value(f64(status))
						resp_map['body'] = Value(body)
						resp_map['ok'] = Value(status >= 200 && status < 300)
						resp_map['protocol'] = Value('Unified')

						mut header_map := map[string]Value{}
						if headers := nm.response_headers[easy_handle] {
							for k, v in headers {
								header_map[k] = Value(v)
							}
						}
						resp_map['headers'] = Value(MapValue{
							items: header_map
							gc:    vm.alloc_header(int(sizeof(MapValue)))
						})

						vm.define_native_in_map_with_context(mut resp_map, 'json', 0,
							[
							Value(body),
						], fn (mut v VM, a []Value) Value {
							body_str := value_to_string(v.current_native_context[0])
							raw := json2.decode[json2.Any](body_str) or {
								return Value(EnumVariantValue{
									enum_name: 'Result'
									variant:   'err'
									values:    [Value('Failed to parse JSON')]
									gc:        v.alloc_header(int(sizeof(MapValue)))
								})
							}
							val := Value(EnumVariantValue{
								enum_name: 'Result'
								variant:   'ok'
								values:    [json_to_value(mut v, raw)]
								gc:        v.alloc_header(int(sizeof(MapValue)))
							})
							return create_resolved_promise(mut v, val)
						})

						vm.define_native_in_map_with_context(mut resp_map, 'text', 0,
							[
							Value(body),
						], fn (mut v VM, a []Value) Value {
							// Return promise that resolves immediately since body is ready
							// TODO: Make this cleaner, for now simpler to just return string?
							// Fetch spec says text() returns promise.
							return create_resolved_promise(mut v, v.current_native_context[0])
						})
						state.value = Value(EnumVariantValue{
							enum_name: 'Result'
							variant:   'ok'
							values:    [
								Value(MapValue{
									items: resp_map
									gc:    vm.alloc_header(int(sizeof(MapValue)))
								}),
							]
							gc:        vm.alloc_header(int(sizeof(MapValue)))
						})
						state.status = .resolved
					}
				}

				if q := nm.stream_queues[easy_handle] {
					q.close()
				}
				if q := nm.ws_queues[easy_handle] {
					q.close()
				}

				// Cleanup
				C.curl_multi_remove_handle(nm.curl_multi_handle, easy_handle)
				C.curl_easy_cleanup(easy_handle)
				nm.active_transfers.delete(easy_handle)
				nm.transfer_bodies.delete(easy_handle)
				nm.stream_queues.delete(easy_handle)
				nm.ws_queues.delete(easy_handle)
				nm.stream_headers_done.delete(easy_handle)
				nm.response_headers.delete(easy_handle)
			}
		}
	}

	// Server polling
	// 1. Check for accepted connections
	for {
		select {
			conn := <-nm.server_accepted {
				if nm.server_accept_queue.len > 0 {
					id := nm.server_accept_queue[0]
					nm.server_accept_queue.delete(0)
					nm.resolve_accept(mut vm, id, conn)
				}
			}
			else {
				break
			}
		}
	}
}

fn (mut nm NetworkManager) resolve_accept(mut vm VM, id int, conn &net.TcpConn) {
	// Minimal HTTP parser
	mut buf := []u8{len: 1024}
	n := conn.read(mut buf) or { 0 }
	req_text := buf[..n].bytestr()

	lines := req_text.split('\r\n')
	mut method := 'GET'
	mut url := '/'
	if lines.len > 0 {
		parts := lines[0].split(' ')
		if parts.len > 0 {
			method = parts[0]
		}
		if parts.len > 1 {
			url = parts[1]
		}
	}

	mut res_map := map[string]Value{}
	res_map['request'] = Value(RequestValue{
		method:  method
		url:     url
		body:    ''
		headers: map[string]string{}
		gc:      vm.alloc_header(int(sizeof(MapValue)))
	})
	res_map['response'] = Value(ResponseValue{
		status: 200
		handle: voidptr(conn)
		gc:     vm.alloc_header(int(sizeof(MapValue)))
	})

	if mut state := vm.promises[id] {
		state.status = .resolved
		state.value = Value(MapValue{
			items: res_map
			gc:    vm.alloc_header(int(sizeof(MapValue)))
		})
	}
}
