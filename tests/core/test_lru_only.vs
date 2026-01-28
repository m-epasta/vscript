@[lru_cache]
fn f(x) {
    println("Computing " + to_string(x));
    return x + 1;
}

println(f(5));
println(f(5));
println(f(10));
