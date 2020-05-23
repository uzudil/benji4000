def main() {
    a := [1,2,3];
    trace("a=" + a);
    trace("a[0]=" + a[0]);
    a[1] := "yo";
    trace("a[1]=" + a[1]);
    trace("a=" + a);

    a[1] := x => x * 2;
    trace("a=" + a);
    xx := a[1](5);
    trace("result=" + xx);
    trace("a[1](15)=" + a[1](15));

    a[1] := [1, 2, x => x + 1];
    trace("a[1][2](9)=" + a[1][2](9));

    a[1][2] := x => [1,2,x];
    trace("a[1][2](9)=" + a[1][2](9));    

    # this doesn't work yet
    trace("a[1][2](9)[2]=" + a[1][2](9)[2]);    
}
