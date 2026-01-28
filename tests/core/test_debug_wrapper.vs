@[memoize]
fn fib(n) {
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

println("Function defined");
let x = fib;
println("Got function");
let result = fib(10);
println("Got result: " + to_string(result));
