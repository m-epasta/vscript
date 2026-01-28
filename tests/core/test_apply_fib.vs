fn fib(n) {
    if (n <= 1) return n;
    return fib(n - 1) + fib(n - 2);
}

fn cached_fib(n) {
    if (n <= 1) return n;
    return apply(cached_fib, [n - 1]) + apply(cached_fib, [n - 2]);
}

println(cached_fib(5));
