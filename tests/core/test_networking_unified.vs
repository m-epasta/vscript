@[test]
fn test_unified_concurrency() {
    import core:http
    import core:http2
    import core:http3
    
    print("Spawning mixed protocol requests...")
    
    let p1 = http.get("https://jsonplaceholder.typicode.com/posts/1")
    let p2 = http2.fetch("https://jsonplaceholder.typicode.com/posts/2", {})
    let p3 = http3.fetch("https://quic.rocks:4433", {}) // Might fallback but will handle
    
    print("Awaiting concurrent results...")
    
    let r1 = await p1
    let r2 = await p2
    let r3 = await p3
    
    assert(r1.is_ok(), "H1 failed")
    assert(r2.is_ok(), "H2 failed")
    
    let h1_res = r1.unwrap()
    let h2_res = r2.unwrap()
    
    print("H1 Status: " + h1_res.status)
    print("H2 Status: " + h2_res.status)
    print("H1 Protocol: " + h1_res.protocol)
    print("H2 Protocol: " + h2_res.protocol)
    
    assert_eq(h1_res.status, 200)
    assert_eq(h2_res.status, 200)
    
    // Verify .json() helper on H1
    let h1_json = h1_res.json()
    assert(h1_json.is_ok(), "H1 JSON helper failed")
    assert_eq(h1_json.unwrap().id, 1)
    
    // Verify .json() helper on H2
    let h2_json = h2_res.json()
    assert(h2_json.is_ok(), "H2 JSON helper failed")
    assert_eq(h2_json.unwrap().id, 2)
}
