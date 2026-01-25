// without Caching
fn fib(n) {
    if (n <= 1) return n 
    return fib(n - 1) + fib(n - 2)
}

var start = clock()
println(fib(30))
var end = clock()
println("Without caching: " + to_string(end - start))

// with Caching
@[lru_cache]
fn fib_cached(n) {
    if (n <= 1) return n 
    return fib_cached(n - 1) + fib_cached(n - 2)
}

var start = clock()
println(fib_cached(30))
var end = clock()
println("Without caching: " + to_string(end - start))
