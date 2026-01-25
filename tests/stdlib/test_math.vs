// Test Math stdlib functions

@[test]
fn test_sqrt() {
    assert_eq(sqrt(4), 2);
    assert_eq(sqrt(9), 3);
    assert(sqrt(2) > 1.41, "sqrt(2) > 1.41");
    assert(sqrt(2) < 1.42, "sqrt(2) < 1.42");
}

@[test]
fn test_floor() {
    assert_eq(floor(3.14), 3);
    assert_eq(floor(3.99), 3);
    assert_eq(floor(-3.14), -4); 
}

@[test]
fn test_abs() {
    assert_eq(abs(-5), 5);
    assert_eq(abs(5), 5);
    assert_eq(abs(0), 0);
}

@[test]
fn test_min_max() {
    assert_eq(min(1, 2), 1);
    assert_eq(min(5, -5), -5);
    assert_eq(max(1, 2), 2);
    assert_eq(max(5, -5), 5);
}

@[test]
fn test_round() {
    assert_eq(round(3.1), 3);
    assert_eq(round(3.5), 4); // Standard round half up usually? or nearest even? 
    // v's round usually rounds to nearest integer. 3.5 -> 4.
    assert_eq(round(3.9), 4);
}

@[test]
fn test_pow() {
    assert_eq(pow(2, 3), 8);
    assert_eq(pow(3, 2), 9);
    assert_eq(pow(4, 0.5), 2); // sqrt
}
