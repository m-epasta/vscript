@[test]
fn test_fs_operations() {
    import core:fs;
    import core:tmpfile;

    var path = tmpfile.random_path();
    var content = "Hello, Filesystem!";

    // 1. Clean up potential leftover
    if (fs.exists(path)) {
        fs.remove(path);
    }

    // 2. Write file
    var res = fs.write_file(path, content);
    assert(res.is_ok(), "Failed to write file: " + res.unwrap_err_or(""));

    // 3. Check existence
    assert(fs.exists(path), "File should exist after write");

    // 4. Read file
    var read_res = fs.read_file(path);
    assert(read_res.is_ok(), "Failed to read file");
    assert_eq(read_res.unwrap(), content);

    // 5. Remove file
    var rm_res = fs.remove(path);
    assert(rm_res.is_ok(), "Failed to remove file");
    assert(!fs.exists(path), "File should be gone");
}
