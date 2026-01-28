fn fib_uncached(n) {
    if (n <= 1) {
        return n;
    }
    return fib_uncached(n - 1) + fib_uncached(n - 2);
}

@[memoize]
fn fib_cached(n) {
    if (n <= 1) {
        return n;
    }
    return fib_cached(n - 1) + fib_cached(n - 2);
}

println("Computing fib(25) without cache...");
let r1 = fib_uncached(25);
println("Result: " + to_string(r1));

println("Computing fib(25) with cache...");
let r2 = fib_cached(25);
println("Result: " + to_string(r2));

if (r1 == r2) {
    println("SUCCESS: Both produce the same result!");
} else {
    println("FAILURE: Results differ");
}
