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
    return null;
}

def array_foreach(array, fx) {
    i := 0; 
    while(i < len(array)) {
        fx(i, array[i]);
        i := i + 1;
    }
}

def choose(array) {
    if(len(array) > 0) {
        return array[random() * len(array)];
    } else {
        return null;
    }
}

def roll(minValue, maxValue) {
    return int(random() * (maxValue - minValue)) + minValue;
}

# todo: make this more efficient
def sort(array, fx) {
    trace("sort before: " + array);
    i := 0;
    while(i < len(array)) {
        t := 0;
        while(t < len(array)) {
            if(fx(array[i], array[t]) < 0) {
                tmp := array[i];
                array[i] := array[t];
                array[t] := tmp;
            }
            t := t + 1;
        }
        i := i + 1;
    }
    trace("sort after: " + array);
}

def array_reverse(array) {
    ret := [];
    i := len(array) - 1;
    while(i >= 0) {
        ret[len(ret)] := array[i];
        i := i - 1;
    }
    return ret;    
}
