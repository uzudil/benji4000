titleMode := 0;
savegameFound := null;

def initTitle() {
    savegameFound := load("savegame.dat");
}

def renderTitle() {
    clearVideo();
    if(titleMode = 0) {
        drawText(20, 30, COLOR_GREEN, COLOR_BLACK, "The Curse of Svaltfen");
        if(savegameFound = null) {
            drawText(20, 185, COLOR_DARK_GRAY, COLOR_BLACK, "Press SPACE to start");
        } else {
            drawText(20, 185, COLOR_DARK_GRAY, COLOR_BLACK, "Press SPACE to continue");
        }
    }
    if(titleMode = 1) {
        drawText(10, 10, COLOR_MID_GRAY, COLOR_BLACK, "...You see a faint light coming closer.");
        drawText(10, 20, COLOR_MID_GRAY, COLOR_BLACK, "Memories from past lives echo in");
        drawText(10, 30, COLOR_MID_GRAY, COLOR_BLACK, "your brain.");

        drawText(10, 50, COLOR_LIGHT_GRAY, COLOR_BLACK, "I have lived before...");
        drawText(10, 60, COLOR_LIGHT_GRAY, COLOR_BLACK, "Walked the earth many eons ago...");

        drawText(10, 80, COLOR_MID_GRAY, COLOR_BLACK, "You remember completing tasks of");
        drawText(10, 90, COLOR_MID_GRAY, COLOR_BLACK, "great evil.");
        drawText(10, 100, COLOR_MID_GRAY, COLOR_BLACK, "But it was necessary then...");
        drawText(10, 110, COLOR_MID_GRAY, COLOR_BLACK, "...And it is so again.");

        drawText(10, 130, COLOR_MID_GRAY, COLOR_BLACK, "You awake then fully, in darkness,");
        drawText(10, 140, COLOR_MID_GRAY, COLOR_BLACK, "somewhere underground.");

        drawText(20, 185, COLOR_DARK_GRAY, COLOR_BLACK, "Press SPACE to start");
    }
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
        if(titleMode < 1) {
            if(savegameFound = null) {
                titleMode := titleMode + 1;
            } else {
                mode := "game";
            }
        } else {
            mode := "game";
        }
    }
    if(mode != "title") {
        MODES[mode].init();
    }
}

