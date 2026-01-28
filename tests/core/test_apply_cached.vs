@[lru_cache]
fn add(a, b) {
    return a + b;
}

let result = apply(add, [2, 3]);
println(result);
