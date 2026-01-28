@[test]
fn test_http_sessions() {
    import core:http
    
    let sess = http.Session();
    print("Session created. Testing cookie persistence...");
    
    // 1. Set a cookie
    let p1 = sess.get("https://httpbin.org/cookies/set?user=elite_vscript");
    let res1 = await p1;
    assert(res1.is_ok(), "First request failed");
    
    // 2. Verify cookie is sent back automatically
    let p2 = sess.get("https://httpbin.org/cookies");
    let res_result = await p2;
    assert(res_result.is_ok(), "Second request failed");
    
    let res2 = res_result.unwrap();
    let data = res2.json().unwrap();
    
    print("Cookies found in response: " + data.cookies);
    // data.cookies should be {"user": "elite_vscript"}
    assert(data.cookies.user == "elite_vscript", "Cookie was NOT persisted!");
    print("Elite Session verified: Cookie persistence confirmed.");
}
