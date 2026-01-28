@[test]
fn test_simple_import() {
    // Import using string literal (maps to letiable 'module_a' from filename)
    // Note: The letiable name derivation logic is "module_a" from "module_a.vs"
    import "tests/core/module_a.vs";
    
    // Check exports
    // Accessing exported map
    assert_eq(module_a.add(1, 2), 3);
    assert_eq(module_a.mod_let, "loaded");
}

@[test]
fn test_import_alias() {
    import "tests/core/module_a.vs" as ma;
    assert_eq(ma.add(10, 20), 30);
}

// TODO: Colon syntax needs proper resolution relative to CWD or root
// If running from vscript root, "tests:core:module_a" -> "tests/core/module_a.vs"
@[test]
fn test_import_colon_syntax() {
    import tests:core:module_a as col;
    assert_eq(col.add(5, 5), 10);
}

@[test]
fn test_module_caching() {
    import "tests/core/module_a.vs" as m1;
    import "tests/core/module_a.vs" as m2;
    
    // Modify one (if maps are ref, should affect other if cached?)
    // Actually, exports are a MapValue (passed by reference).
    m1.mod_let = "modified";
    assert_eq(m2.mod_let, "modified");
}
