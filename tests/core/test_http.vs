@[test]
fn test_http_request() {
    import core:http
    import core:json
    
    // 1. Test GET with await
    var res_promise = await http.get("https://jsonplaceholder.typicode.com/posts/1")
    assert(res_promise.is_ok(), "HTTP GET failed")
    
    var res = res_promise.unwrap()
    assert(res.ok, "Response not OK")
    assert_eq(res.status, 200)
    
    // Parse body (manually for now as .json() helper is placeholder)
    var data = json.parse(res.body).unwrap()
    assert_eq(data.id, 1)
}

@[test]
fn test_http_404() {
    import core:http
    var res_promise = await http.get("https://jsonplaceholder.typicode.com/invalid-path-12345")
    var res = res_promise.unwrap()
    assert(!res.ok, "Should not be OK")
    assert_eq(res.status, 404)
}

@[test]
fn test_http_post() {
    import core:http
    var body = '{"title": "foo", "body": "bar", "userId": 1}'
    var res_promise = await http.post("https://jsonplaceholder.typicode.com/posts", body)
    var res = res_promise.unwrap()
    assert_eq(res.status, 201)
}
