// test_gc_auto.vs
println("Starting Auto GC test...");

i = 0;
while (i < 10000) {
    // Large allocation
    data = [1, 2, 3, 4, i];
    
    if (i % 2000 == 0) {
        println("Iteration: " + i);
    }
    i = i + 1;
}

println("Auto GC test complete.");
