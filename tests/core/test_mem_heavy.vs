fn leak() {
    var a = [];
    for (var i = 0; i < 10000; i++) {
        push(a, "data string " + i);
    }
}

print("Starting heavy memory test...");
for (var i = 0; i < 500; i++) {
    if (i % 50 == 0) print("Iteration " + i);
    leak();
}
print("Memory test finished.");
