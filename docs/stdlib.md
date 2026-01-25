# vscript Standard Library

A comprehensive guide to the built-in functions, decorators, and iteration helpers available in vscript.

## Printers
Functions for outputting data to standard streams.

### `print(val)`
Outputs a value followed by a newline to stdout.
```vscript
print("Hello World");
```

### `eprint(val, ...)`
Outputs values to stderr.
```vscript
eprint("Error:", "Something went wrong");
```

### `printf(fmt, ...args)`
Formatted output using placeholders (`%s`).
```vscript
printf("User: %s, ID: %s\n", "Alice", 123);
```

---

## Math Optimizations
High-performance native math operations.

### `abs(x)`
Returns the absolute value.
```vscript
print(abs(-10)); // 10
```

### `min(a, b, ...)` / `max(a, b, ...)`
Returns the minimum or maximum of a set of numbers.
```vscript
print(min(5, 2, 8)); // 2
```

### `sqrt(x)` / `pow(base, exp)` / `floor(x)` / `round(x)`
Standard math functions.
```vscript
print(sqrt(16)); // 4
print(pow(2, 3)); // 8
```

---

## Strings & Arrays
Helpers for data manipulation.

### `len(obj)`
Returns the length of a string or array.
```vscript
print(len([1, 2, 3])); // 3
```

### `push(arr, val)`
Appends a value to an array. Returns the added value.
```vscript
var a = [1];
push(a, 2);
print(a); // [1, 2]
```

### `slice(obj, start, [end])`
Returns a sub-portion of a string or array.
```vscript
print(slice("vscript", 0, 1)); // "v"
```

### `trim(str)` / `is_empty(obj)`
String cleanup and metadata.
```vscript
print(trim("  trim me  ")); // "trim me"
```

---

## Type Verification
Rust-style character and type checkers.

### `type(val)`
Returns the type string: `"number"`, `"string"`, `"boolean"`, `"nil"`, `"function"`, or `"array"`.
```vscript
print(type(123)); // "number"
```

### `is_digit(str)` / `is_alpha(str)` / `is_alphanumeric(str)`
Checks if all characters in the string match the class.
```vscript
print(is_digit("123")); // true
```

### `is_lowercase(str)` / `is_uppercase(str)` / `is_whitespace(str)`
Case and space verification.

---

## Functional Iteration
Methods for processing sequences using closures.

### `range(stop)` / `range(start, stop, [step])`
Generates an array of numbers.
```vscript
print(range(5)); // [0, 1, 2, 3, 4]
```

### `map(arr, func)`
Transforms each element using a function.

### `filter(arr, func)`
Keeps elements matching the predicate.

### `reduce(arr, func, initial)`
Combines elements into a single value.

### `find(arr, func)` / `any(arr, func)` / `all(arr, func)`
Search and logic helpers.

### `first(arr)` / `last(arr)`
Accessors for the start and end of arrays.

---

## Decorators & Caching
High-level function wrappers for performance.

### `memoize(func)`
Returns a version of the function that caches results.

### `lru_cache(func, capacity)`
Advanced memoization with a Least Recently Used eviction policy.

### `apply(func, args_array)` 
Invokes a function with an array of arguments.

## Utilities
### `clock()`
Returns high-precision monotonic time (seconds).
var start = clock();
// ...
print(clock() - start);
