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
        "save image: S",
        "new image: N",
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