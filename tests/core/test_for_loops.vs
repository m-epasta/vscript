println("=== For Loop Tests ===");

println("\nTest 1: Basic for loop with increment");
let sum = 0;
for (let i = 0; i < 5; i++) {
    sum = sum + i;
}
println("Sum of 0..4 = " + to_string(sum)); // Should be 10

println("\nTest 2: For loop with decrement");
let countdown = 0;
for (let j = 5; j > 0; j--) {
    countdown = countdown + 1;
}
println("Countdown iterations = " + to_string(countdown)); // Should be 5

println("\nTest 3: For loop with custom increment");
let result = 0;
for (let k = 0; k < 20; k = k + 2) {
    result = result + k;
}
println("Sum of evens 0..18 = " + to_string(result)); // Should be 90

println("\nTest 4: For loop with no initializer");
let x = 0;
for (; x < 3; x++) {
    println("  x = " + to_string(x));
}

println("\nTest 5: Nested for loops");
let total = 0;
for (let i = 0; i < 3; i++) {
    for (let j = 0; j < 2; j++) {
        total = total + 1;
    }
}
println("Total iterations (3x2) = " + to_string(total)); // Should be 6

println("\n=== All for loop tests passed! ===");
