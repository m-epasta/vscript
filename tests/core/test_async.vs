@[test]
fn test_async_syntax() {
    async fn foo() {
        return "async works"
    }
    
    // Testing await syntax (even if it's currently sync in VM)
    let result = await foo()
    assert_eq(result, "async works")
}

@[test]
fn test_await_raw() {
    let val = await 42
    assert_eq(val, 42)
}

@[test]
fn test_async_expr() {
    let my_func = async fn(x) { return x * 2; }
    let res = await my_func(21)
    assert_eq(res, 42)
}
