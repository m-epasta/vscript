@[test]
fn test_ws_echo() {
    import core:ws
    
    print("Connecting to echo server...");
    // wss://echo.websocket.org is often down/changing, using a known safe libcurl test endpoint if possible
    // or httpbin. but httpbin WS is limited.
    // Try piehost echo or similar
    let connect_promise = ws.connect("wss://echo.piehost.com/v3/1?api_key=oCdZl9Z7YAt3vO7pS6MvAcp96Abeu7S9zTsgS7B2");
    
    let res_result = await connect_promise;
    assert(res_result.is_ok(), "WS Handshake failed: " + res_result.unwrap());
    
    let socket = res_result.unwrap();
    print("Handshake OK! Sending message...");
    
    let send_ok = socket.send("vscript WebSocket test");
    assert(send_ok, "Failed to send message");
    
    print("Waiting for echo response...");
    let msg_promise = socket.recv();
    let echo = await msg_promise;
    
    print("Received echo: " + echo);
    assert(echo.contains("vscript"), "Echo content mismatch!");
    
    socket.close();
    print("Native WebSockets verified!");
}
