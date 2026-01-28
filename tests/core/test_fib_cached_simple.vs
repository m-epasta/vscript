@[lru_cache]
fn fib_cached(n) {
    println("fib_cached called with " + to_string(n));
    if (n <= 1) return n 
    return fib_cached(n - 1) + fib_cached(n - 2)
}

let result = fib_cached(5);
println("Result: " + to_string(result));
