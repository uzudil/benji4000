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
        "clone/copy image: C",
        "delete image: D",
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

def inputImageName(prompt, mustIncludeName) {
    s := input(prompt);
    while((mustIncludeName = true && composite[s] = null) || (mustIncludeName = false && composite[s] != null)) {
        print("Invalid name. Image names are:");
        k := keys(composite);
        i := 0;
        while(i < len(k)) {
            print("\t" + k[i]);
            i := i + 1;
        }
        print(" ");
        s := input(prompt);
    }
    return s;
}

def loadImageMode() {
    # save the work so far
    composite[name] := img;

    setVideoMode(0);
    setBackground(COLOR_LIGHT_BLUE);    
    clearVideo();
    
    s := inputImageName("Load image name? ", true);
    switchTo(s);

    mode := PAINT_MODE;
    setVideoMode(2);
    setBackground(COLOR_BLACK);    
    clearVideo();
}

def deleteImageMode() {
    # save the work so far
    composite[name] := img;

    setVideoMode(0);
    setBackground(COLOR_LIGHT_BLUE);    
    clearVideo();
    
    s := inputImageName("Delete which image? ", true);
    del composite[s];
    k := keys(composite);
    if(len(k) > 0) {
        switchTo(k[0]);
    }

    mode := PAINT_MODE;
    setVideoMode(2);
    setBackground(COLOR_BLACK);
    clearVideo();
    if(len(k) = 0) {
        width := 64;
        height := 64;
        x := width / 2;
        y := height / 2;
        img := getImage(2, 2, 2 + width, 2 + height);
        name := "Drawing";
        composite[name] := img;
    }
}

def cloneImageMode() {
    # save the work so far
    composite[name] := img;

    setVideoMode(0);
    setBackground(COLOR_LIGHT_BLUE);    
    clearVideo();
    
    s := inputImageName("Choose an unused image name: ", false);
    name := s;
    composite[name] := img;
    
    mode := PAINT_MODE;
    setVideoMode(2);
    setBackground(COLOR_BLACK);    
    clearVideo();
}
