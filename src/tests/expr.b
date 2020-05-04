# try various spacings
a:=1;
b:=2+3;
c := 3 + 4;
# and negative numbers
d := -1;
bb := true;
bb2 := d = -1;
bb3 := d > -1;
bb4 := bb || false;

def main() {
    assert(a, 1);
    assert(b, 5);
    assert(c, 7);
    assert(d, -1);
    assert(b * d, -5);
    
    # booleans
    trace("bb=" + bb);
    trace("bb2=" + bb2);
    trace("bb3=" + bb3);
    trace("bb3 is false=" + (bb3 = false));
    trace("bb4=" + bb4);
    
    e1 := [ true, false ];
    e2 := [ true, false ];
    i := 0;
    while(i < len(e1)) {
        t := 0;
        while(t < len(e1)) {
            trace("" + e1[i] + " && " + e2[t] + "=" + (e1[i] && e2[t]));
            trace("" + e1[i] + " || " + e2[t] + "=" + (e1[i] || e2[t]));
            t := t + 1;
        }
        i := i + 1;
    }
    trace("Done");
}
