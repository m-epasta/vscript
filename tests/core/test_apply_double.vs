fn double(n) {
    return n + n;
}

let result = apply(double, [5]);
println("Result: " + to_string(result));
