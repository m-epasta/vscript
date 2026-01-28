@[metadata: "tag"]
fn test_attr() {
    println("Metadata function executed.")
}

test_attr();

struct Point {
    x f64 = 0.0,
    y f64 = 0.0,
    label string = "origin"
}

enum Color {
    red,
    green,
    blue
}

println("Advanced type syntax parsed successfully.")

let p = Point();
println("Struct instance created.")
println("p.x default: ${to_string(p.x)}")
println("p.label default: ${to_string(p.label)}")

p.x = 42.0;
println("p.x adjusted: ${to_string(p.x)}")


print("Enum access:\n ${Color.green}\n ${Color.green}\n ${Color.blue}")
