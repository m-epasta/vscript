@[test]
fn test_http_get() {
    import core:http
    import core:json
    
    // Test against a public API
    var res = http.get("https://jsonplaceholder.typicode.com/posts/1")
    assert(res.is_ok(), "HTTP GET failed")
    
    var body = res.unwrap()
    assert(len(body) > 0, "Empty response")
    
    // Parse JSON response
    var data = json.parse(body)
    assert(data.is_ok(), "Failed to parse response JSON")
}
