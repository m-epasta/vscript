// Comprehensive test for string interpolation and integer display

// 1. Integer display fix
let port = 8080.0;
let pi = 3.14159;
print("SERVER_INFO: Port=${port}, PI=${pi}");

// 2. Simple interpolation
let name = "vscript";
let greeting = "Hello, ${name}!";
print("GREETING: " + greeting);

// 3. Complex expressions in interpolation
let a = 10;
let b = 20;
let calc = "Result: ${a} + ${b} = ${a + b}";
print("CALC: " + calc);

// 4. Nested interpolation or complex structures
let items = ["apple", "banana"];
let nested = "Items count: ${items.length()}";
print("NESTED: " + nested);

// 5. Mixed interpolation and concatenation
let final = "Total: " + "${a + b}" + " units";
print("FINAL: " + final);
