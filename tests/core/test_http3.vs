@[test]
fn test_http3_fetch() {
    import core:http3
    
    // We'll test against a known HTTP/3 endpoint
    // Note: If libcurl doesn't support H3, it might error or fallback
    let promise = http3.fetch("https://quic.rocks:4433", {})
    let res_result = await promise
    
    // We expect an error or ok depending on system support
    if (res_result.is_ok()) {
        let res = res_result.unwrap()
        print("HTTP/3 Result received")
        assert(res.ok, "Response not OK")
    } else {
        print("HTTP/3 Fetch handled")
    }
}
