# input handling functions

def isShiftDown() {
    return isKeyDown(KeyLeftShift) || isKeyDown(KeyRightShift);
}

def getCursorSpeed() {
    if(isShiftDown() && isKeyDown(KeySpace) = false) {
        return 4;
    } else {
        return 1;
    }
}

def handleInput() {

    # start timer when first key is down
    if(anyKeyDown()) {
        if(getTicks() < timer) {
            return 0;
        }
        timer := getTicks() + 0.1;
    } else {
        # reset timer on key up
        timer := 0;
        return 0;
    }

    if(isKeyDown(KeyH)) {
        mode := HELP_MODE;
    }
    if(isKeyDown(KeyRightBracket)) {
        if(isShiftDown()) {
            bcolor := bcolor + 1;
            if(bcolor >= 16) {
                bcolor := 0;
            }        
        } else {
            color := color + 1;
            if(color >= 16) {
                color := 0;
            }
        }
    }
    if(isKeyDown(KeyLeftBracket)) {
        if(isShiftDown()) {
            bcolor := bcolor - 1;
            if(bcolor < 0) {
                bcolor := 15;
            }        
        } else {
            color := color - 1;
            if(color < 0) {
                color := 15;
            }
        }
    }
    if(isKeyDown(KeyUp)) {
        y := y - getCursorSpeed();
        if(y < 0) {
            y := y + height;
        }
    }
    if(isKeyDown(KeyDown)) {
        y := y + getCursorSpeed();
        if(y >= height) {
            y := y - height;
        }
    }
    if(isKeyDown(KeyLeft)) {
        x := x - getCursorSpeed();
        if(x < 0) {
            x := x + width;
        }
    }
    if(isKeyDown(KeyRight)) {
        x := x + getCursorSpeed();
        if(x >= width) {
            x := x - width;
        }
    }
    if(isKeyDown(KeySpace)) {
        c := color;
        if(isShiftDown()) {
            c := bcolor;
        }
        setPixel(x + 2, y + 2, c);
        img := getImage(2, 2, 2 + width, 2 + height);
    }
}
