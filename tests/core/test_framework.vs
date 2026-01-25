// Test the internal test framework

@[test]
fn test_addition() {
    assert(1 + 1 == 2, "Math is broken");
    assert_eq(1 + 1, 2);
}

@[test]
fn test_string_concat() {
    var s = "hello " + "world";
    assert_eq(s, "hello world");
}

fn helper() {
    return 42;
}

@[test]
fn test_helper_call() {
    var res = helper();
    assert_eq(res, 42);
}

// This should NOT run
fn not_a_test() {
    assert(false, "This should not run");
}

@[cfg(test)]
fn test_only_helper() {
    return "test mode only";
}

@[test]
fn test_cfg() {
    // This function should exist only in test mode
    // We can't easily check for existence dynamically yet without reflection on globals map
    // effectively, if this code compiles and runs, we are good.
    var s = test_only_helper();
    assert_eq(s, "test mode only");
}
