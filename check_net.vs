import net
fn main() {
    l := net.listen_tcp(.ip, ':0') or { panic(err) }
    c := l.accept() or { panic(err) }
    println(typeof(c).name)
}
