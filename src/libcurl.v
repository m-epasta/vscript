module main

#flag -lcurl
#include <curl/curl.h>

struct C.CURL {}

struct C.CURLM {}

type CurlEasy = voidptr
type CurlMulti = voidptr

fn C.curl_easy_init() &C.CURL
fn C.curl_easy_setopt(handle &C.CURL, option int, parameter voidptr) int
fn C.curl_easy_perform(handle &C.CURL) int
fn C.curl_easy_cleanup(handle &C.CURL)
fn C.curl_easy_getinfo(handle &C.CURL, info int, parameter voidptr) int

// WebSocket API (Curl 7.86+)
struct C.curl_ws_frame {
	age       int
	flags     int
	offset    i64
	bytesleft i64
	len       usize
}

fn C.curl_ws_recv(handle &C.CURL, buffer voidptr, buflen usize, recv &usize, meta &&C.curl_ws_frame) int
fn C.curl_ws_send(handle &C.CURL, buffer voidptr, buflen usize, send &usize, fragsize i64, flags int) int
fn C.curl_ws_meta(handle &C.CURL) &C.curl_ws_frame

type CurlHeaderFn = fn (&char, usize, usize, voidptr) usize

fn C.curl_multi_init() &C.CURLM
fn C.curl_multi_add_handle(multi_handle &C.CURLM, easy_handle &C.CURL) int
fn C.curl_multi_remove_handle(multi_handle &C.CURLM, easy_handle &C.CURL) int
fn C.curl_multi_perform(multi_handle &C.CURLM, still_running &int) int
fn C.curl_multi_wait(multi_handle &C.CURLM, extra_fds &voidptr, extra_nfds int, timeout_ms int, ret_nfds &int) int
fn C.curl_multi_poll(multi_handle &C.CURLM, extra_fds &voidptr, extra_nfds int, timeout_ms int, ret_nfds &int) int
fn C.curl_multi_cleanup(multi_handle &C.CURLM)
fn C.curl_multi_info_read(multi_handle &C.CURLM, msgs_in_queue &int) &C.CURLMsg

struct C.CURLSH {}

fn C.curl_share_init() &C.CURLSH
fn C.curl_share_setopt(handle &C.CURLSH, option int, parameter voidptr) int
fn C.curl_share_cleanup(handle &C.CURLSH)

struct C.CURLMsg {
	msg         int
	easy_handle &C.CURL
	data        voidptr // union
}

// Option constants (subset)
const curlopt_url = 10002
const curlopt_writefunction = 20011
const curlopt_headerfunction = 20079
const curlopt_writedata = 10001
const curlopt_useragent = 10018
const curlopt_http_version = 10084
const curlopt_pipewait = 10237
const curl_http_version_2_0 = 3
const curl_http_version_3 = 4
const curl_http_version_3only = 5
const curlm_ok = 0
const curlmsg_done = 1
const curl_pipewait = 1

// WebSocket constants
const curlws_text = 1
const curlws_binary = 2
const curlws_cont = 4
const curlws_close = 8
const curlws_ping = 16
const curlws_pong = 32

// Share constants
const curlopt_share = 10100
const curlshopt_share = 1
const curl_lock_data_cookie = 2
const curl_lock_data_dns = 3
const curl_lock_data_ssl_session = 4
const curl_lock_data_connect = 5

// TransferContext stores heap-allocated state for an active curl transfer
// We use this to collect data chunks for non-streaming requests
@[heap]
struct TransferContext {
pub mut:
	body string
}

// Context passed to libcurl callbacks
struct CurlCallbackContext {
pub mut:
	vm          &VM
	easy_handle voidptr
}

// Global-style callback compatible with C
fn write_callback(data &char, size usize, nmemb usize, userdata voidptr) usize {
	if userdata == 0 {
		return 0
	}
	unsafe {
		mut ctx := &CurlCallbackContext(userdata)
		len := size * nmemb
		chunk := data.vstring_with_len(int(len))

		// Access VM via context
		mut v := ctx.vm
		h := ctx.easy_handle

		// If streaming is enabled for this handle, push to queue
		if q := v.net_manager.stream_queues[h] {
			q <- chunk
		}

		// Always append to buffer if one exists
		if body_s_ptr := v.net_manager.transfer_bodies[h] {
			mut s_ref := &string(body_s_ptr)
			*s_ref += chunk
		}

		return len
	}
}

// Header callback to detect end of handshake
fn header_callback(data &char, size usize, nmemb usize, userdata voidptr) usize {
	if userdata == 0 {
		return 0
	}
	unsafe {
		mut ctx := &CurlCallbackContext(userdata)
		len := size * nmemb
		line := data.vstring_with_len(int(len))

		// V's net.http uses "\r\n" as delimiter
		// The end of headers is an empty line (just \r\n or \n)
		if line == '\r\n' || line == '\n' {
			ctx.vm.net_manager.stream_headers_done[ctx.easy_handle] = true
		}

		return len
	}
}

// We'll wrap these into a nicer V API if needed,
// but stdlib_http2.v will use them directly for extreme control.
