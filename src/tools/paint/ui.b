# ui functions

def drawTexts(text) {
    i := 0;
    cy := 5;
    while(i < len(text)) {
        drawText(5, cy, COLOR_MID_GRAY, COLOR_BLACK, text[i]);
        i := i + 1;
        cy := cy + 10;
    }
}

def helpMode() {
    setVideoMode(1);
    clearVideo();
    drawTexts([
        "move: cursor keys", 
        "move fast: shift + cursor keys",
        "color: []",
        "background: shift + []",
        "draw: space",
        "erase: shift + space",
        "new image: N",
        "save image: S",        
        "load image: L",
        "fill: F",
        "fill background: shift + F",
        "Press space to return"
    ]);
    updateVideo();
    
    blockUntilKey(KeySpace);

    mode := PAINT_MODE;
    setVideoMode(2);
}

def newImageMode() {
    # save the work so far
    composite[name] := img;

    setVideoMode(0);
    setBackground(COLOR_LIGHT_BLUE);    
    clearVideo();
    
    name := input("Image name? ");
    width := int(input("Width? "));
    if(width < 4) {
        width := 4;
    }
    if(width > 64) {
        width := 64;
    }
    height := int(input("Height? "));
    if(height < 4) {
        height := 4;
    }
    if(height > 64) {
        height := 64;
    }
    x := width/2;
    y := height/2;
    img := {};

    mode := PAINT_MODE;
    setVideoMode(2);
    setBackground(COLOR_BLACK);    
    clearVideo();
    img := getImage(2, 2, 2 + width, 2 + height);
}

def saveImageMode() {
    # save the work so far
    composite[name] := img;
    save(FILE_NAME, composite);

    setVideoMode(1);
    clearVideo();
    drawTexts([
        "Image data saved.", 
        "Press space to return"
    ]);
    updateVideo();
    
    blockUntilKey(KeySpace);

    mode := PAINT_MODE;
    setVideoMode(2);
}

def loadImageMode() {
    # save the work so far
    composite[name] := img;

    setVideoMode(0);
    setBackground(COLOR_LIGHT_BLUE);    
    clearVideo();
    
    s := input("Load image name? ");
    while(composite[s] = null) {
        print("Invalid name. Valid names are:");
        k := keys(composite);
        i := 0;
        while(i < len(k)) {
            print("\t" + k[i]);
            i := i + 1;
        }
        print(" ");
        s := input("Load image name? ");
    }
    switchTo(s);

    mode := PAINT_MODE;
    setVideoMode(2);
    setBackground(COLOR_BLACK);    
    clearVideo();
}
