@[lru_cache]
fn identity(x) {
    println("identity called with " + to_string(x));
    return x;
}

let a = identity(3);
let b = identity(2);
println("a = " + to_string(a));
println("b = " + to_string(b));
let result = a + b;
println("result = " + to_string(result));
