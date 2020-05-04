def fib(x) {
    if (x = 0) {
        return 0;
    }
    if (x = 1) {
        return 1;
    }
    return fib(x - 1) + fib(x - 2);
}

const FIB = [0, 1, 1, 2, 3, 5, 8, 13, 21, 34];

def main() {
    x := 0;
    while(x < 10) {
        f := fib(x);
        print("at " + x + " fib=" + f);
        assert(f, FIB[x], "Incorrect fib number at x=" + x);
        x := x + 1;
    }
    return x;
}
