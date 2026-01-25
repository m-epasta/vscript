printf("abs(-10): %s\n", abs(-10));
printf("min(5, 3, 8): %s\n", min(5, 3, 8));
printf("max(5, 3, 8): %s\n", max(5, 3, 8));
printf("pow(2, 3): %s\n", pow(2, 3));
printf("round(4.6): %s\n", round(4.6));

var arr = [1, 2, 3, 4, 5];
var doubled = map(arr, fn(x) { return x * 2; });
printf("Map doubled: %s\n", doubled);

var evens = filter(arr, fn(x) { return x % 2 == 0; });
printf("Filter evens: %s\n", evens);

var sum = apply(fn(a, b) { return a + b; }, [10, 20]);
printf("Apply sum: %s\n", sum);
