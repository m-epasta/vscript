fn test_add(a, b) {
    println("Adding: " + to_string(a) + " + " + to_string(b));
    let result = a + b;
    println("Result: " + to_string(result));
    return result;
}

let x = test_add(3, 2);
println("Final: " + to_string(x));
