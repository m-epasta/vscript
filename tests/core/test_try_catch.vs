@[test]
fn test_catch_panic() {
    var caught = false;
    var msg = "";
    try {
        // Trigger runtime error: calling a number
        var x = 1;
        x();
    } catch (e) {
        caught = true;
        msg = e;
    }
    assert(caught, "Did not catch runtime error");
    // Verify message contains reason
    assert(msg == "Can only call functions and classes", "Wrong error message: " + msg);
}

@[test]
fn test_execution_continues() {
    var step = 0;
    try {
        step = 1;
        var x = 1;
        x(); // panic
        step = 2; // Should skip
    } catch (e) {
        step = 3;
    }
    assert_eq(step, 3);
}

@[test]
fn test_nested_catch() {
    var log = "";
    try {
        try {
            var x = 1;
            x(); // panic
        } catch (e) {
            log = log + "inner";
        }
        log = log + "->outer";
    } catch (e) {
        log = log + "FAIL";
    }
    assert_eq(log, "inner->outer");
}

@[test]
fn test_catch_binding() {
    try {
        var x = 1;
        x();
    } catch (err) {
        assert(len(err) > 0, "Error message should not be empty");
    }
}
