def main() {
    a := 1;
    assert("number", typeof(a));
    a := true;
    assert("boolean", typeof(a));
    a := "hello";
    assert("string", typeof(a));
    a := [1, 2, "aaa"];
    assert("array", typeof(a));
    a := { "a": 1, "b": 2 };
    assert("map", typeof(a));    
    a := x => x * 2;
    assert("function", typeof(a));    
    trace("Done!");
}