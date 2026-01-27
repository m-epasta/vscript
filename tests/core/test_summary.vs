// Comprehensive test for string interpolation and integer display

// 1. Integer display fix
var port = 8080.0;
var pi = 3.14159;
print("SERVER_INFO: Port=${port}, PI=${pi}");

// 2. Simple interpolation
var name = "vscript";
var greeting = "Hello, ${name}!";
print("GREETING: " + greeting);

// 3. Complex expressions in interpolation
var a = 10;
var b = 20;
var calc = "Result: ${a} + ${b} = ${a + b}";
print("CALC: " + calc);

// 4. Nested interpolation or complex structures
var items = ["apple", "banana"];
var nested = "Items count: ${items.length()}";
print("NESTED: " + nested);

// 5. Mixed interpolation and concatenation
var final = "Total: " + "${a + b}" + " units";
print("FINAL: " + final);
