def b(x) {
    x := x * 2;
    assert(x, 200, "should be 200");
    print("x in b:" + x);
    return x;
}

def a(x) {
    x := x * x;
    assert(x, 100, "should be 100");
    print("x in a:" + x);

    x := b(x);
    assert(x, 200, "should be 200");
    print("x in a again:" + x);

    return x;
}

def main() {

    # do some math
    x := 2 * (7 - 2);
    assert(x, 10, "should be 10");
    print("x=" + x);

    a(x);
    assert(x, 10, "should be 10");

    # show it
    print("x is currently:" + x);

    return x;
}
