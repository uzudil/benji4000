# map demo

def foo(m) {
    m["added in foo"] := "heck yeah";
}

def make_map() {
    return { "xxx": 123, "yyy": "zaza" };
}

def main() {
    # create a map
    map := { "a": 1, "b": 2, "c": 3 };
    assert(map, { "a": 1, "b": 2, "c": 3 });
    print("map is " + map);
    print("value for 'a' is: " + map["a"]);
    assert(map["a"], 1);
    print("value for 'b' is: " + map["b"]);
    assert(map["b"], 2);
    print("value for 'c' is: " + map["c"]);
    assert(map["c"], 3);
    print("value for non-existing key: " + map["d"]);
    assert(map["d"], null);

    # iterate the keys
    keys := keys(map);
    i := 0;
    while(i < len(keys)) {
        print("i=" + i + " key=" + keys[i]);
        i := i + 1;
    }

    # update same value
    map["b"] := map["b"] * 2;
    assert(map["b"], 4);
    print("map after updating existing key, using the key: " + map);

    # assignment to map: update an existing key
    map["a"] := 22;
    assert(map["a"], 22);
    print("map after updating existing key: " + map);

    # add a new key
    map["zorro"] := "hello world";
    assert(map["zorro"], "hello world");
    print("map after adding a key: " + map);

    # delete a key + value from the map
    del map["b"];
    assert(map, { "a": 22, "zorro": "hello world", "c": 3 });
    print("map after deleting a key: " + map);

    # pass by reference
    foo(map);
    assert(map["added in foo"], "heck yeah");
    print("map after pass by reference: " + map);

    # return by reference
    new_map := make_map();
    assert(new_map, { "xxx": 123, "yyy": "zaza" });
    print("new map created in a function: " + new_map);

    # with trailing comma
    withcomma := { "a": 1, "b": 2, };
    trace("with comma:" + withcomma);

    print("Done");
}
