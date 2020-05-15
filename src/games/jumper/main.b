player := {
    "sprite": 0,
    "x": 80,
    "y": 88,
    "imgIndex": 0,
    "timer": 0
};

def main() {
    setVideoMode(2);
    setBackground(COLOR_BLACK);
    clearVideo();

    img := load("img.dat");

    # create sprites
    imglist := [img["pl1"], img["pl2"], img["pl3"], img["pl2"]];
    setSprite(player["sprite"], imglist);

    #clearVideo();
    drawText(10, 180, COLOR_WHITE, COLOR_BLACK, "Press SPACE");
    drawSprite(player["x"], player["y"], player["sprite"], player["imgIndex"], 0, 0);
    
    # draw some rocks
    y := 100;
    while(y < 200) {
        x := 0;
        while(x < 160) {
            drawImage(x, y, img["rock" + int(random() * 2 + 1)]);
            x := x + 24;
        }
        y := y + 24;
    }
    updateVideo();

    while(isKeyDown(KeySpace) != true) {
        if(getTicks() > player["timer"]) {
            move := false;
            if(isKeyDown(KeyLeft) && player["x"] > 0) {
                move := true;
                flipX := 0;
                player["x"] := player["x"] - 1;
            }
            if(isKeyDown(KeyRight) && player["x"] < 160) {
                move := true;
                flipX := 1;
                player["x"] := player["x"] + 1;
            }
            if(move) {
                player["imgIndex"] := player["imgIndex"] + 0.1;
                if(player["imgIndex"] >= len(imglist)) {
                    player["imgIndex"] := 0;
                }
                drawSprite(player["x"], player["y"], player["sprite"], player["imgIndex"], flipX, 0);
            }
            player["timer"] := getTicks() + 0.01;
        }
    }
}