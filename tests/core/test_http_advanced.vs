@[test]
fn test_http_non_blocking() {
    import core:http
    
    // Multiple requests spawned at once (non-blocking)
    let p1 = http.get("https://jsonplaceholder.typicode.com/posts/1")
    let p2 = http.get("https://jsonplaceholder.typicode.com/posts/2")
    
    let r1_res = await p1
    let r2_res = await p2
    
    assert(r1_res.is_ok(), "Request 1 failed")
    assert(r2_res.is_ok(), "Request 2 failed")
    
    let res1 = r1_res.unwrap()
    assert_eq(res1.status, 200)
}

@[test]
fn test_http_json_helper() {
    import core:http
    
    let r_res = await http.get("https://jsonplaceholder.typicode.com/posts/1")
    let res = r_res.unwrap()
    
    // Using the NEW .json() helper method!
    let data_res = res.json()
    assert(data_res.is_ok(), "JSON parse helper failed")
    
    let data = data_res.unwrap()
    assert_eq(data.id, 1)
    assert(len(data.title) > 0)
}
