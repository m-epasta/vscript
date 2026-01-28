@[memoize]
fn fib(n) {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
}

let result = fib(35);
println(result);
