def main() {
    # some looping code
    x := 10;
    assert(x, 10, "should be 10");
    while(x >= 0) {
        print("x is " + (x * 0.5));
        x := x - 1;
    }
    assert(x, -1, "should be -1");
    return x;
}
