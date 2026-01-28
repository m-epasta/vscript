@[memoize]
fn expensive_free(x) {
    println("Computing " + to_string(x));
    return x * x;
}

println(expensive_free(10));
println(expensive_free(10));
println(expensive_free(20));
