# multi-dimensional array testing
a := [
    [1, 2, 3, 4, 5],
    ["a", "b", "c", "d", "e"]
];

def foo() {
    b := a[1];
    del b[2];
}

def main() {

    print("a=" + a);

    b := a[0];
    print("b=" + b);

    print("a[0][2]=" + a[0][2]);

    print("BEFORE a[0][3]=" + a[0][3]);
    a[0][3] := "zorro";
    print("AFTER a[0][3]=" + a[0][3]);
    print("AFTER a=" + a);
    print("AFTER b=" + b);

    print("Deleting b[1]...");
    del b[1]; # maybe del should be a function
    print("b=" + b);
    print("a=" + a);

    foo();
    print("After deleting a[1][2]: " + a);

    c := a[0][2];
    print("Element at 0,2: " + c);

    del a[0][2];
    print("Deleting 0,2: " + a);

    complex := [
        { 
            "name": "gabor", 
            "age": 48 
        },
        {
            "name": "abe",
            "age": 19
        },
        {
            "name": "asha",
            "age": 14
        }
    ];
    print("Complex array:" + complex);
    print("complex[1]:" + complex[1]);
    print("complex[1][name]:" + complex[1]["name"]);
}