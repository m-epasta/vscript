// Test High-Level Error Handling (Result/Option)
// NOTE: Result and Option are built-in types

fn safe_div(a, b) {
    if (b == 0) {
        return Result.err("Division by zero");
    }
    return Result.ok(a / b);
}

// 1. Test basic construction and printing
println("Testing Result construction:");
var r1 = safe_div(10, 2);
var r2 = safe_div(10, 0);
println(r1); // Should show variant
println(r2);

// 2. Test helper methods
println("\nTesting helper methods:");
println("r1.is_ok(): " + to_string(r1.is_ok()));
println("r2.is_err(): " + to_string(r2.is_err()));

var val = r1.unwrap();
println("r1.unwrap(): " + to_string(val));

// 3. Test expect (should panic on err)
// println(r2.expect("Should fail")); // Uncomment to test panic

// 4. Test Pattern Matching
println("\nTesting match expression:");

fn print_result(res) {
    var output = match res {
        Result.ok(v) => "Success: " + to_string(v),
        Result.err(e) => "Error: " + e,
        _ => "Unknown result"
    };
    println(output);
}

print_result(r1);
print_result(r2);

// 5. Test Option-like behavior
/*
enum Option {
    some(val),
    none
}
*/

var opt = Option.some(42);
var empty = Option.none;

val = match opt {
    Option.some(x) => x * 2,
    Option.none => 0
};
println("Option match result: " + to_string(val));
println("Option unwrap: " + to_string(opt.unwrap()));
