def imgTest() {
    setBackground(COLOR_BLACK);
    clearVideo();

    # draw something
    fillRect(10, 10, 50, 50, COLOR_RED);
    fillCircle(50, 50, 30, COLOR_GREEN);

    # copy it
    img := getImage(10, 10, 50, 50);

    # draw it somewhere else
    i := 0;
    while(i < 3) {
        drawImage(i * 50, 100, img);
        i := i + 1;
    }
        
    drawText(10, 180, COLOR_WHITE, COLOR_BLACK, "Press SPACE");
    while(isKeyDown(KeySpace) != true) {
        updateVideo();
    }
}

def main() {
    setVideoMode(1);
    
    imgTest();

    # wait for keypress to stop
    while(isKeyDown(KeySpace) = true) {
        updateVideo();
    }

    setVideoMode(2);
    imgTest();
}