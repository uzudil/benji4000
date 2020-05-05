def drawColors() {
    i := 0;
    w := 9;
    while(i < 16) {
        fillRect(i * w, 0, (i + 1) * w, 20, i);
        i := i + 1;
    }
}

def main() {
    setVideoMode(2);
    setBackground(0);

    clearVideo();
    drawColors();
    drawText(0, 40, 1, 0, "Press SPACE");

    # wait for keypress
    while(isKeyDown(KeySpace) != true) {
        updateVideo();
    }

    # wait for keypress to stop
    while(isKeyDown(KeySpace) = true) {
        updateVideo();
    }

    # cycle palette colors (except background)
    blue := 0;
    timer := 0;
    while(isKeyDown(KeySpace) != true) {

        if(getTicks() > timer) {
            i := 1;
            while(i < 16) {
                setColor(i, 0, 0, blue);
                i := i + 1;
                blue := blue + 256/16;
                if(blue >= 256) {
                    blue := blue - 256;
                }
            }
            timer := getTicks() + 0.025;
        }

        clearVideo();
        drawColors();
        drawText(0, 40, 1, 0, "Press SPACE to stop");
        updateVideo();
    }
}