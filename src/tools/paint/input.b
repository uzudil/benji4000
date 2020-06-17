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

# the first pause is longer allowing a user to move per-pixel
const FIRST_STEP = 0.5;
const SECOND_STEP = 0.05;
keyDownStep := FIRST_STEP;

def handleInput() {

    if(anyNonHelperKeyDown()) {
        # while a key is down, use timer
        if(getTicks() < timer) {
            return 0;
        }
        timer := getTicks() + keyDownStep;
        if(keyDownStep = FIRST_STEP) {
            keyDownStep := SECOND_STEP;
        }
    } else {
        # reset timer on key up
        if(timer != 0) {
            timer := 0;
            keyDownStep := FIRST_STEP;
        }
        return 0;
    }

    if(isKeyDown(Key1)) {
        setVideoMode(1);
    }
    if(isKeyDown(Key2)) {
        setVideoMode(2);
    }
    if(isKeyDown(KeyH)) {
        mode := HELP_MODE;
    }
    if(isKeyDown(KeyN)) {
        mode := NEW_IMAGE_MODE;
    }
    if(isKeyDown(KeyS)) {
        mode := SAVE_IMAGE_MODE;
    }
    if(isKeyDown(KeyL)) {
        mode := LOAD_IMAGE_MODE;
    }
    if(isKeyDown(KeyC)) {
        mode := CLONE_IMAGE_MODE;
    }
    if(isKeyDown(KeyD)) {
        mode := DELETE_IMAGE_MODE;
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
    if(isKeyDown(KeyF)) {
        flood(x + 2, y + 2, color);
        img := getImage(2, 2, 2 + width, 2 + height);
    }
    if(isKeyDown(KeySpace)) {
        if(isShiftDown()) {
            if(pendown != 2) {
                pendown := 2;
            } else {
                pendown := 0;
            }
        } else {
            if(pendown != 1) {
                pendown := 1;
            } else {
                pendown := 0;
            }
        }
    }
    if(pendown >= 1) {
        c := color;
        if(pendown = 2) {
            c := bcolor;
        }
        setPixel(x + 2, y + 2, c);
        img := getImage(2, 2, 2 + width, 2 + height);
    }
}

def blockUntilKey(key) {
    while(isKeyDown(key) = false) {        
    }
    while(isKeyDown(key)) {
    }
}
