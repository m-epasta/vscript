@[lru_cache]
fn add(a, b) {
    println("add(" + to_string(a) + ", " + to_string(b) + ") called");
    return a + b;
}

@[memoize]
fn multiply(x, y) {
    println("multiply(" + to_string(x) + ", " + to_string(y) + ") called");
    return x * y;
}

println("=== LRU Cache Test ===");
println(to_string(add(2, 3)));  // Should print "add(2, 3) called"
println(to_string(add(2, 3)));  // Should NOT print (cached)
println(to_string(add(3, 4)));  // Should print "add(3, 4) called"

println("=== Memoize Test ===");
println(to_string(multiply(5, 6)));  // Should print "multiply(5, 6) called"
println(to_string(multiply(5, 6)));  // Should NOT print (cached)
println(to_string(multiply(7, 8)));  // Should print "multiply(7, 8) called"

println("=== Success ===");
