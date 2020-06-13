const SPRITE_INDEX = 0;

pos := [
    { "x": 20, "dir": 1, "y": 100, "ydir": 1 },
    { "x": 60, "dir": -1, "y": 100, "ydir": 1 },
    { "x": 100, "dir": 1, "y": 100, "ydir": -1 },
    { "x": 140, "dir": -1, "y": 100, "ydir": -1 }
];
imgIndex := 0;

def move(p) {
    p["x"] := p["x"] + p["dir"];
    if(p["x"] >= 160) {
        p["dir"] := -1;
    }
    if(p["x"] < 0) {
        p["dir"] := 1;
    }
    p["y"] := p["y"] + p["ydir"];
    if(p["y"] >= 200) {
        p["ydir"] := -1;
    }
    if(p["y"] < 0) {
        p["ydir"] := 1;
    }
}

def main() {
    setVideoMode(2);
    setBackground(COLOR_DARK_BLUE);
    clearVideo();

    img := load("img.dat");

    # create sprites
    imglist := [img["man1"], img["man2"], img["man3"], img["man2"]];
    setSprite(SPRITE_INDEX, imglist);
    setSprite(SPRITE_INDEX + 1, imglist);
    setSprite(SPRITE_INDEX + 2, imglist);
    setSprite(SPRITE_INDEX + 3, imglist);
    setSprite(SPRITE_INDEX + 4, imglist);

    #clearVideo();
    drawText(10, 180, COLOR_WHITE, COLOR_BLACK, "Press SPACE");
    updateVideo();

    timer := 0;
    imgTimer := 0;
    while(isKeyDown(KeySpace) != true) {
        # notice: no clearVideo() in loop

        if(getTicks() > timer) {
            # draw the sprite
            i := 0;
            while(i < 4) {
                drawSprite(pos[i]["x"], pos[i]["y"], SPRITE_INDEX + i, imgIndex, 0, 0);
                move(pos[i]);
                i:=i+1;
            }
            timer := getTicks() + 0.005;
            if(getTicks() > imgTimer) {
                imgIndex := imgIndex + 1;
                if(imgIndex >= len(imglist)) {
                    imgIndex := 0;
                }
                imgTimer := getTicks() + 0.1;
            }
        }

        # draw another one so we can see the animation
        drawSprite(30, 150, SPRITE_INDEX + 4, imgIndex, 0, 0);

        updateVideo();
    }
}