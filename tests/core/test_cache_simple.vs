@[lru_cache]
fn id(x) {
    return x;
}

let a = id(5);
println("a = " + to_string(a));
