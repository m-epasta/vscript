@[test]
fn test_json_parse() {
    import core:json;
    
    let res = json.parse('{"name": "test", "value": 42}');
    assert(res.is_ok(), "Failed to parse JSON");
    
    let obj = res.unwrap();
    assert_eq(obj["name"], "test");
    assert_eq(obj["value"], 42);
}

@[test]
fn test_json_stringify() {
    import core:json;
    
    let obj = {"key": "value", "num": 123};
    let str = json.stringify(obj);
    assert(len(str) > 0, "Stringify returned empty");
}

@[test]
fn test_json_array() {
    import core:json;
    
    let res = json.parse('[1, 2, 3]');
    assert(res.is_ok(), "Failed to parse array");
    
    let arr = res.unwrap();
    assert_eq(len(arr), 3);
    assert_eq(arr[0], 1);
}

@[test]
fn test_json_roundtrip() {
    import core:json;
    
    let original = {"users": [{"name": "Alice"}, {"name": "Bob"}]};
    let str = json.stringify(original);
    let parsed = json.parse(str).unwrap();
    
    assert_eq(parsed["users"][0]["name"], "Alice");
}
