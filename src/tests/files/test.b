def main() {
    m := { "s": "hello", "n": 15, "f": 12.5, "b": true, "list": [1, 2, 3, 4], "double": [ [ "a", "b" ], [ "c", "d" ] ] };
    print("m=" + m);

    # you can only save map-type variables and only when running in a sandbox (from a directory)
    save("data.dat", m);

    n := load("data.dat");
    print("n=" + n);

    assert(len(keys(n)), len(keys(m)));
    assert(n.s, m.s);
    assert(n.n, m.n);
    assert(n.b, m.b);
    assert(n.list, m.list);

    # make sure arrays are loaded correctly
    assert(n.list[2], 3);
    assert(n.double[1][0], "c");
}
