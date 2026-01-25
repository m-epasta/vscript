// Test Advanced Type Syntax: Structs, Enums, and Attributes

@[version: 1.0]
@[author: "vscript_standard"]
fn meta_func() {
    print "Metadata function executed.";
}

// Typed Struct with default values
struct Point {
    @[required]
    x f64 = 0.0;
    y f64 = 0.0;
    label string = "origin";
}

// Enum for sum types
enum Color {
    red,
    green,
    blue
}

// Verify that the toolchain parses and stubs these correctly
meta_func();
print "Advanced type syntax parsed successfully.";

var p = Point();
print "Struct instance (syntax stub) created.";
