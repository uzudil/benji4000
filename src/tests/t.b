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
}
