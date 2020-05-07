const SPRITE_INDEX = 0;

x := 80;
dir := 1;
y := 100;
ydir := 1;    
imgIndex := 0;

def move() {
    x := x + dir;
    if(x >= 160) {
        dir := -1;
        x := 159;
    }
    if(x < 0) {
        dir := 1;
        x := 0;
    }
    y := y + ydir;
    if(y >= 200) {
        ydir := -1;
        y := 199;
    }
    if(y < 0) {
        ydir := 1;
        y := 0;
    }
}

def main() {
    setVideoMode(2);
    setBackground(COLOR_DARK_BLUE);
    clearVideo();

    # draw something
    fillRect(10, 10, 50, 50, COLOR_RED);
    fillCircle(50, 50, 30, COLOR_GREEN);

    drawText(10, 180, COLOR_WHITE, COLOR_BLACK, "Press SPACE");

    # copy it
    img1 := getImage(10, 10, 50, 50);
    img2 := getImage(15, 10, 55, 50);
    img3 := getImage(20, 10, 60, 50);

    # set it as sprite 0
    setSprite(SPRITE_INDEX, [img1, img2, img3]);

    timer := 0;
    imgTimer := 0;
    while(isKeyDown(KeySpace) != true) {
        if(getTicks() > timer) {
            # draw the sprite
            drawSprite(x, y, SPRITE_INDEX, imgIndex);
            move();
            timer := getTicks() + 0.005;
        }
        if(getTicks() > imgTimer) {
            imgIndex := imgIndex + 1;
            if(imgIndex >= 3) {
                imgIndex := 0;
            }
            imgTimer := getTicks() + 0.05;
        }
        updateVideo();
    }
}