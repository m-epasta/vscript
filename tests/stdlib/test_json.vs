// Test JSON stdlib

@[test]
fn test_encode_decode() {
    var obj = {
        "name": "vscript",
        "version": 1,
        "features": ["simple", "fast"]
    };

    var json_str = json_encode(obj);
    // JSON string order is not guaranteed, so checking exact string match is flaky.
    // Instead, decode it back and check properties.
    
    var decoded = json_decode(json_str);
    
    assert_eq(decoded["name"], "vscript");
    assert_eq(decoded["version"], 1);
    assert_eq(len(decoded["features"]), 2);
    assert_eq(decoded["features"][0], "simple");
}

@[test]
fn test_primitives() {
    assert_eq(json_decode("123"), 123);
    assert_eq(json_decode("true"), true);
    assert_eq(json_decode("\"hello\""), "hello");
}
