def initTitle() {
}

def renderTitle() {
    drawText(20, 30, COLOR_GREEN, COLOR_BLACK, "The Title");
    drawText(20, 45, COLOR_MID_GRAY, COLOR_BLACK, "Press SPACE to start");

}

def titleInput() {
    if(isKeyDown(KeyE)) {
        while(isKeyDown(KeyE)) {
        }
        mode := "editor";
    }
    if(isKeyDown(KeySpace)) {
        while(isKeyDown(KeySpace)) {
        }
        mode := "game";
    }
    if(mode != "title") {
        MODES[mode].init();
    }
}

