def main() {
    a := [
        ["c","d"],
        2,
        3,
        [ "a", "b", "c" ],
        x => x + 1,
        [ "z", "x", x => [1, 2, x] ],
    ];

    trace(a[5][2](10)[2]);
    trace("complicated expression=" + a[5][2](10)[2]);

    a[1] := 15;
    trace("a[1]=" + a[1]);
    trace(a);

    a[len(a)] := "fin";
    trace(a);

    a[3][1] := "middle";
    trace(a);
    trace(a[3][1]);
    trace(a[3]);
    trace(substr(a[3][1], 2, 2));

    del a[3][1];
    trace(a);

    a[1] := { "a": 1, "b": 2, "c": 3 };
    trace(a);
    trace(a[1].b);

    trace("a[5][len(a[5]) - 1]=" + a[5][len(a[5]) - 1]);
    last := len(a[5]);
    a[5][last] := "xxx";
    trace(a);
    
    a[5][len(a[5])] := "yyy";
    trace(a);

    trace("done");
}
