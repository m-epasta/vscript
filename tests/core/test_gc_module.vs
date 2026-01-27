import core:gc

println("Starting GC test...")
println("Initial threshold: " + gc.threshold())

// Allocate some garbage
i = 0
while (i < 1000) {
    a = [1, 2, 3, 4, 5]
    i = i + 1
}

println("Running manual collection...")
gc.collect()

println("Setting new threshold...")
gc.set_threshold(5242880) // 5MB
println("New threshold: " + gc.threshold())

println("GC test complete.");
