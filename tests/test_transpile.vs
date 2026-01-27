enum Status {
    active
    inactive
    pending
}

struct User {
    name string
    age int
}

fn check_status(s) {
    match s {
        Status.active => { print("Active"); }
        Status.inactive => { print("Inactive"); }
        other => { print("Unknown"); }
    }
}

// Struct instantiation not fully sugary yet, using map effectively
// But we want to test transpilation of the definition
var u = {name: "Alice", age: 30}
print(u.name)
// Enum usage
print(Status.active)
check_status(Status.active)
