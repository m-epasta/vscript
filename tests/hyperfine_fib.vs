// Simple recursive Fibonacci
@[lru_cache]
fn fib(n) {
    if (n <= 1) {
        return n
    }
    return fib(n - 1) + fib(n - 2)
}

fib(62)
// println(fib(62))
