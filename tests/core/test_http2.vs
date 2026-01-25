@[test]
fn test_http2_fetch() {
    import core:http2
    
    // We'll test against a reliable HTTP/2 enabled endpoint
    var promise = http2.fetch("https://http2.akamai.com/demo", {})
    var res_result = await promise
    
    assert(res_result.is_ok(), "HTTP/2 Fetch failed")
    
    var res = res_result.unwrap()
    assert(res.ok, "Response not OK")
    assert_eq(res.status, 200)
    assert(res.protocol.contains("HTTP/2"))
    assert(len(res.body) > 0)
}

@[test]
fn test_http2_parallel() {
    import core:http2
    
    // Test multiplexing potential by spawning multiple requests
    var p1 = http2.fetch("https://jsonplaceholder.typicode.com/posts/1", {})
    var p2 = http2.fetch("https://jsonplaceholder.typicode.com/posts/2", {})
    
    var r1 = await p1
    var r2 = await p2
    
    assert(r1.is_ok(), "P1 failed")
    assert(r2.is_ok(), "P2 failed")
    
    assert_eq(r1.unwrap().status, 200)
    assert_eq(r2.unwrap().status, 200)
}
