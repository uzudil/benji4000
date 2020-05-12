def main() {
    m := { "s": "hello", "n": 15, "f": 12.5, "b": true };
    print("m=" + m);

    # you can only save map-type variables and only when running in a sandbox (from a directory)
    save("data.dat", m);

    n := load("data.dat");
    print("n=" + n);

    k := keys(n);
    i := 0;
    while(i < len(k)) {
        print("Testing " + k[i]);
        assert(n[k[i]], m[k[i]]);
        i := i + 1;
    }
    assert(i, len(keys(m)));
}
