@[test]
fn test_http_streaming() {
    import core:http
    
    print("Requesting large file stream...");
    let promise = http.request("https://jsonplaceholder.typicode.com/photos", {
        "stream": true
    });
    
    let res_result = await promise;
    assert(res_result.is_ok(), "Fetch failed");
    
    let res = res_result.unwrap();
    print("Handshake OK! Protocol: " + res.protocol);
    assert_eq(res.status, 200);
    
    let stream = res.body;
    let total_len = 0;
    let chunks = 0;
    
    while (!stream.is_closed()) {
        let chunk = await stream.read();
        
        if (chunk != nil) {
            total_len = total_len + len(chunk);
            chunks = chunks + 1;
        }
    }
    
    print("Stream finished. Received " + total_len + " bytes in " + chunks + " chunks.");
    assert(total_len > 0, "No data received");
}
