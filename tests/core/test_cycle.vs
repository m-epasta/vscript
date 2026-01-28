println("Testing for loop with i++");
let sum = 0;
for (let i = 0; i < 10; i++) {
    sum = sum + i;
}
println("Sum of 0..9 = " + to_string(sum));

println("Testing for loop with i--");
let count = 5;
for (let j = 5; j > 0; j--) {
    count = count - 1;
}
println("Count = " + to_string(count));

println("For loop test completed successfully!");
