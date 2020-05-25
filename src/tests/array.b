###############################
# program to demo arrays

# function modifies an array passed by reference
def foo(list) {
    list[2] := 55;
}

# creates an array (on the heap) and passes it back by reference
def create_array() {
    a := [ "abc", "def", "ghi" ];
    return a;
}

# this where execution starts
def main() {
    # declare an array
    a := [ 1, 2, 3, 4, 5 ];
    
    # print it, or a part of it
    print("a=" + a);
    print("at index=2, " + a[2]);
    assert(a[2], 3);

    # array element assignment
    a[0] := 13;
    assert(a[0], 13);
    print("After setting index 0, " + a[0]);

    # array element on RHS
    x := a[0];
    assert(x, 13);
    print("Afer reading index 0, " + x);

    # array element dynamic access
    i := 0;
    while (i < len(a)) {
        a[i] := a[i] * 2;
        i := i + 1;
    }
    print("After dynamic access " + a);
    assert(a, [26, 4, 6, 8, 10]);

    # append to an array by adding a new element at the end
    i := 0;
    while(i < 3) {
        a[len(a)] := i;
        i := i + 1;
    }
    assert(a, [26, 4, 6, 8, 10, 0, 1, 2]);    
    print("After adding 3 elements " + a);

    # delete from array
    del a[0];
    assert(a, [4, 6, 8, 10, 0, 1, 2]);
    print("After removing element 0: " + a + " length=" + len(a));
    del a[3];
    assert(a, [4, 6, 8, 0, 1, 2]);
    print("After removing element 3: " + a + " length=" + len(a));

    # pass by reference
    foo(a);
    assert(a, [4, 6, 55, 0, 1, 2]);
    print("After pass by reference " + a);

    # create array in function
    list := create_array();
    assert(a, [4, 6, 55, 0, 1, 2]);
    assert(list, ["abc", "def", "ghi"]);
    print("After create in function, a=" + a);
    print("After create in function, list=" + list);

    withcomma := [1,2,3,];
    trace("with comma=" + withcomma);

    a := [ 1, 2, "a", x => x * 2 ];
    trace(a[0]);
    trace(a[1]);
    trace(a[2]);

    trace(a[3](15));
    assert(a[3](15), 30);

    trace("Done");
}
