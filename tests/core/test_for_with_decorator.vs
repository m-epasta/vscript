@[memoize]
fn fibonacci(n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

println("Computing fibonacci numbers using for loop:");
for (let i = 0; i < 10; i++) {
    let fib_val = fibonacci(i);
    println("fib(" + to_string(i) + ") = " + to_string(fib_val));
}

println("\nAll fibonacci computations completed successfully!");
