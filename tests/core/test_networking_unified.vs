@[test]
fn test_unified_concurrency() {
    import core:http
    import core:http2
    import core:http3
    
    print("Spawning mixed protocol requests...")
    
    var p1 = http.get("https://jsonplaceholder.typicode.com/posts/1")
    var p2 = http2.fetch("https://jsonplaceholder.typicode.com/posts/2", {})
    var p3 = http3.fetch("https://quic.rocks:4433", {}) // Might fallback but will handle
    
    print("Awaiting concurrent results...")
    
    var r1 = await p1
    var r2 = await p2
    var r3 = await p3
    
    assert(r1.is_ok(), "H1 failed")
    assert(r2.is_ok(), "H2 failed")
    
    var h1_res = r1.unwrap()
    var h2_res = r2.unwrap()
    
    print("H1 Status: " + h1_res.status)
    print("H2 Status: " + h2_res.status)
    print("H1 Protocol: " + h1_res.protocol)
    print("H2 Protocol: " + h2_res.protocol)
    
    assert_eq(h1_res.status, 200)
    assert_eq(h2_res.status, 200)
    
    // Verify .json() helper on H1
    var h1_json = h1_res.json()
    assert(h1_json.is_ok(), "H1 JSON helper failed")
    assert_eq(h1_json.unwrap().id, 1)
    
    // Verify .json() helper on H2
    var h2_json = h2_res.json()
    assert(h2_json.is_ok(), "H2 JSON helper failed")
    assert_eq(h2_json.unwrap().id, 2)
}
