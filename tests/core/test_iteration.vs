// Test iteration and caching built-ins
print("--- Testing Range ---");
let r = range(5);
print(r); // [0, 1, 2, 3, 4]
print(range(2, 5)); // [2, 3, 4]
print(range(1, 10, 2)); // [1, 3, 5, 7, 9]

print("--- Testing Functional ---");
let arr = [1, 2, 3, 4, 5];
let sum = reduce(arr, fn(acc, x) { return acc + x; }, 0);
print(sum); // 15

let found = find(arr, fn(x) { return x > 3; });
print(found); // 4

print(any(arr, fn(x) { return x > 10; })); // false
print(any(arr, fn(x) { return x > 4; }));  // true
print(all(arr, fn(x) { return x > 0; }));  // true
print(all(arr, fn(x) { return x > 2; }));  // false

print("--- Testing Property Helpers ---")
print(first(arr)); // 1
print(last(arr));  // 5

print("--- Testing LRU Cache ---");
let call_count = 0;
fn slow_fn(x) {
    call_count = call_count + 1
    return x * 2;
}

let cached = lru_cache(slow_fn, 2)
print(cached(10)); // 20
print(cached(10)); // 20 (cached)
print(cached(20)); // 40
print(cached(30)); // 60 (evicts 10)
print(cached(10)); // 20 (re-calculated)
print(call_count); // Should be 4
