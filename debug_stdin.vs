import core:os as os

fn main() {
    while (true) {
        let line = os.stdin_read_line()
        if (line == nil || line == "") break
        os.log("LINE: " + line)
    }
}
