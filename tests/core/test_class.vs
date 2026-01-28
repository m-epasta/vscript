// Test classes and objects
class Person {
    init(name, age) {
        this.name = name;
        this.age = age;
    }

    say_hello() {
        print("Hi, I'm " + this.name + " and I am " + to_string(this.age) + " years old.");
    }

    celebrate_birthday() {
        this.age = this.age + 1;
        print("Happy birthday " + this.name + "! You are now " + to_string(this.age));
    }
}

let p = Person("Alice", 30);
p.say_hello();
p.celebrate_birthday();

println("Direct field access:");
println(p.name);
p.city = "New York";
println(p.city);
