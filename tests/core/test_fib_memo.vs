// Test Automatic Caching Attributes
// Fibonacci with @[lru_cache] should be O(n) instead of O(2^n)

let start = clock();

@[lru_cache]
fn fib(n) {
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
}

let result = fib(35);
let end = clock();

println("fib(35) = " + to_string(result));
println("Time taken: " + to_string(end - start) + "s");

// Also test @[memoize] on a method
class Calc {
    @[memoize]
    expensive(x) {
        println("Computing expensive value for " + to_string(x));
        return x * x;
    }
}

let c = Calc();
println(c.expensive(10));
println(c.expensive(10)); // Should be cached (no compute message)
println(c.expensive(20));
