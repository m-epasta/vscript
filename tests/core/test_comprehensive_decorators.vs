// Test 1: Simple memoization
@[memoize]
fn factorial(n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

// Test 2: LRU cache with capacity
@[lru_cache]
fn expensive_compute(x) {
    // Simulate expensive computation
    let result = 0;
    let i = 0;
    while (i < 1000) {
        result = result + i;
        i = i + 1;
    }
    return result + x;
}

// Test 3: Mutual recursion with caching
@[memoize]
fn is_even(n) {
    if (n == 0) {
        return true;
    }
    return is_odd(n - 1);
}

@[memoize]
fn is_odd(n) {
    if (n == 0) {
        return false;
    }
    return is_even(n - 1);
}

println("Test 1: Factorial");
println("factorial(5) = " + to_string(factorial(5)));
println("factorial(10) = " + to_string(factorial(10)));

println("Test 2: Expensive compute (should use cache)");
println("Result 1: " + to_string(expensive_compute(5)));
println("Result 2: " + to_string(expensive_compute(5)));  // Cached
println("Result 3: " + to_string(expensive_compute(10)));

println("Test 3: Mutual recursion");
println("is_even(0) = " + to_string(is_even(0)));
println("is_even(5) = " + to_string(is_even(5)));
println("is_even(10) = " + to_string(is_even(10)));
println("is_odd(5) = " + to_string(is_odd(5)));
println("is_odd(10) = " + to_string(is_odd(10)));

println("=== All tests passed! ===");
