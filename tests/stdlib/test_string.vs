// Test String stdlib functions

@[test]
fn test_to_string() {
    assert_eq(to_string(123), "123");
    assert_eq(to_string(true), "true");
    assert_eq(to_string(nil), "nil");
}

@[test]
fn test_to_number() {
    assert_eq(to_number("123"), 123);
    assert_eq(to_number("12.5"), 12.5);
    // invalid number returns 0? or nil? or error?
    // Implementation usually returns error or 0.
    // Let's assume standard behavior for now.
}

@[test]
fn test_len() {
    assert_eq(len("hello"), 5);
    assert_eq(len(""), 0);
}

@[test]
fn test_slice() {
    var s = "hello world";
    assert_eq(slice(s, 0, 5), "hello");
    assert_eq(slice(s, 6, 11), "world");
}

@[test]
fn test_trim() {
    assert_eq(trim("  hello  "), "hello");
    assert_eq(trim("\nhello\t"), "hello");
}

@[test]
fn test_checks() {
    assert(is_digit("1"));
    assert(!is_digit("a"));
    assert(is_alpha("a"));
    assert(!is_alpha("1"));
    assert(is_empty(""));
    assert(!is_empty(" "));
}
