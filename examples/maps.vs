// Example: Map-based data processing
student = {
    name: "Alice",
    grade: 92,
    subject: "Math"
}

println("Name: " + student["name"])
println("Grade: " + str(student["grade"]))

if student["grade"] >= 90 {
    println("Letter grade: A")
} else if student["grade"] >= 80 {
    println("Letter grade: B")
} else {
    println("Letter grade: C")
}
