class Calc {
    @[memoize]
    expensive(x) {
        println("Computing expensive value for " + to_string(x));
        return x * x;
    }
}

let c = Calc();
println(c.expensive(10));
println(c.expensive(10));
println(c.expensive(20));
