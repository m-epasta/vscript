fn leak() {
    var a = [];
    for (var i = 0; i < 1000; i++) {
        push(a, "data" + i);
    }
    // a goes out of scope here
}

print("Starting memory test...");
for (var i = 0; i < 1000; i++) {
    if (i % 100 == 0) print("Iteration " + i);
    leak();
}
print("Memory test finished.");
