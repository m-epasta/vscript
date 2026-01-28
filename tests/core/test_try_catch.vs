@[test]
fn test_catch_panic() {
    let caught = false;
    let msg = "";
    try {
        // Trigger runtime error: calling a number
        let x = 1;
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
    let step = 0;
    try {
        step = 1;
        let x = 1;
        x(); // panic
        step = 2; // Should skip
    } catch (e) {
        step = 3;
    }
    assert_eq(step, 3);
}

@[test]
fn test_nested_catch() {
    let log = "";
    try {
        try {
            let x = 1;
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
        let x = 1;
        x();
    } catch (err) {
        assert(len(err) > 0, "Error message should not be empty");
    }
}
