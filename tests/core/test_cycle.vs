fn circular() {
    var a = { "next": nil };
    var b = { "next": a };
    a.next = b; // Cycle: a -> b -> a
}

print("Starting circular reference test...");
for (var i = 0; i < 100000; i++) {
    circular();
}
print("Circular reference test finished.");
