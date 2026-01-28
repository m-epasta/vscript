@[memoize]
fn fib(n) {
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

let result = fib(10);
println(to_string(result));
