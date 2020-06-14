def array_map(a, f) {
    b := [];
    i := 0;
    while(i < len(a)) {
        b[len(b)] := f(a[i]);
        i := i + 1;
    }
    return b;
}

def array_filter(a, f) {
    b := [];
    i := 0;
    while(i < len(a)) {
        if(f(a[i])) {
            b[len(b)] := a[i];
        }
        i := i + 1;
    }
    return b;
}

def array_find_index(array, fx) {
    i := 0; 
    while(i < len(array)) {
        if(fx(array[i])) {
            return i;
        }
        i := i + 1;
    }
    return -1;
}

def array_find(array, fx) {
    i := 0; 
    while(i < len(array)) {
        if(fx(array[i])) {
            return array[i];
        }
        i := i + 1;
    }
    return -1;
}

def array_foreach(a, fx) {
    i := 0; 
    while(i < len(array)) {
        fx(i, array[i]);
        i := i + 1;
    }
}
