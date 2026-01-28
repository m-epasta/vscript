@[memoize]
fn double(n) {
    println("double called with n=" + to_string(n));
    let sum = n + n;
    println("n + n = " + to_string(sum));
    return sum;
}

println("===== With decorator =====");
let result = double(5);
println("Result: " + to_string(result));
