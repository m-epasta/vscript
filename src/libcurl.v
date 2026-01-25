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

fn C.curl_multi_init() &C.CURLM
fn C.curl_multi_add_handle(multi_handle &C.CURLM, easy_handle &C.CURL) int
fn C.curl_multi_remove_handle(multi_handle &C.CURLM, easy_handle &C.CURL) int
fn C.curl_multi_perform(multi_handle &C.CURLM, still_running &int) int
fn C.curl_multi_cleanup(multi_handle &C.CURLM)
fn C.curl_multi_info_read(multi_handle &C.CURLM, msgs_in_queue &int) &C.CURLMsg

struct C.CURLMsg {
	msg         int
	easy_handle &C.CURL
	data        voidptr // union
}

// Option constants (subset)
const curlopt_url = 10002
const curlopt_writefunction = 20011
const curlopt_writedata = 10001
const curlopt_useragent = 10018
const curlopt_http_version = 10084
const curlopt_pipewait = 10237
const curl_http_version_2_0 = 3
const curlm_ok = 0
const curlmsg_done = 1
const curl_pipewait = 1

// Helper to write body
fn write_callback(data &char, size usize, nmemb usize, userdata &string) usize {
	unsafe {
		mut s := userdata
		len := size * nmemb
		*s += data.vstring_with_len(int(len))
		return len
	}
}

// We'll wrap these into a nicer V API if needed,
// but stdlib_http2.v will use them directly for extreme control.
