fn circular() {
    let a = { "next": nil };
    let b = { "next": a };
    a.next = b; // Cycle: a -> b -> a
}

print("Starting circular reference test...");
for (let i = 0; i < 100000; i++) {
    circular();
}
print("Circular reference test finished.");
