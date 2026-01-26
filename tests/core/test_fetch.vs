@[test]
fn test_fetch_get() {
    import core:fetch
    
    // Fetch a JS file to test headers and text()
    // Using a reliable CDN endpoint
    var url = "https://cdnjs.cloudflare.com/ajax/libs/jquery/3.6.0/jquery.min.js"
    var res_promise = await fetch.fetch(url, {})
    var res = res_promise.unwrap()
    
    assert(res.ok, "Fetch failed")
    assert_eq(res.status, 200)
    
    // Test Headers
    var headers = res.headers
    print("Headers keys: " + headers.keys().len())
    // Content-Type should be present (case might vary, but usually lowercase in HTTP/2+)
    // Our parser trims spaces but preserves case.
    // Let's print headers to see
    // for k, v in headers { print(k + ": " + v) }
    
    // Test text()
    var text_promise = await res.text()
    var text = text_promise.unwrap()
    assert(text.len > 0, "Body empty")
    assert(text.contains("jQuery"), "Body incorrect")
}

@[test]
fn test_fetch_json() {
    import core:fetch
    
    var url = "https://jsonplaceholder.typicode.com/todos/1"
    var res_promise = await fetch.fetch(url, {})
    var res = res_promise.unwrap()
    
    assert(res.ok, "JSON Fetch failed")
    
    var json_promise = await res.json()
    var data = json_promise.unwrap()
    
    assert_eq(data.id, 1)
}
