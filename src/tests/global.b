# global vars demo

value := 10;


def foo() {
    print("in foo, value=" + value);
    value := 30;
}

def foo2(x) {
    print("in foo2, x=" + x);
    x := x * 100;
    print("in foo2, updated x=" + x);
    return x;
}

def foo3(value) {
    print("in foo3, shadowed value=" + value);
    value := 1000;
    print("in foo3, updated shadowed value=" + value);
}

def main() {
    print("value=" + value);
    assert(value, 10);

    value := value * 2;
    assert(value, 20);
    print("value=" + value);

    foo();
    assert(value, 30);
    print("after foo, value=" + value);

    new_value := foo2(value);
    assert(value, 30);
    assert(new_value, 3000);
    print("after foo2, value=" + value);
    print("after foo2, new_value=" + new_value);

    foo3(5);
    assert(value, 30);
    print("after foo3, value=" + value);
}