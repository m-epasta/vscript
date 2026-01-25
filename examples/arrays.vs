// Example: Array processing
fn sum(numbers) {
    total = 0
    for i = 0; i < numbers.len(); i = i + 1 {
        total = total + numbers[i]
    }
    return total
}

fn average(numbers) {
    return sum(numbers) / numbers.len()
}

scores = [85, 92, 78, 95, 88]
println("Total: " + str(sum(scores)))
println("Average: " + str(average(scores)))
