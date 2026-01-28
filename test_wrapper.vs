// Test script to debug the lru_cache wrapper issue
@[lru_cache]
fn test_func(n) {
    println("Computing test_func(${n})")
    return n * 2
}

println("Calling test_func(5):")
result = test_func(5)
println("Result: ${result}")
