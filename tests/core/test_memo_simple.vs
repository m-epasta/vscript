@[memoize]
fn double(n) {
    return n + n;
}

let result = double(5);
println("Result: " + to_string(result));
