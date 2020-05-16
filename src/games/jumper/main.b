const SPEED_SLOW = 0.1;
const SPEED_FAST = 0.01;
const JUMP_AIR_TIME = 0.25;
const VERTICAL_SPEED = 0.01;

player := {
    "sprite": 0,
    "x": 80,
    "y": 88,
    "imgIndex": 0,
    "timer": 0,
    "speed": SPEED_SLOW,
    "sinceMove": 0,
    "flipX": 0,
    "jump": 0,
    "jumpMove": 0,
    "gravity": 0
};
img := null;
imglist := null;

def movePlayer() {
    player["sinceMove"] := player["sinceMove"] + 1;
    if(player["sinceMove"] > 2) {
        player["speed"] := SPEED_FAST;
    }
    step := 0.1;
    if(player["speed"] = SPEED_SLOW) {
        step := 1;
    }
    player["imgIndex"] := player["imgIndex"] + step;
    if(player["imgIndex"] >= len(imglist)) {
        player["imgIndex"] := 0;
    }
}

def initGame() {
    setVideoMode(2);
    setBackground(COLOR_BLACK);
    clearVideo();

    img := load("img.dat");

    # create sprites
    imglist := [img["pl1"], img["pl2"], img["pl3"], img["pl2"]];
    setSprite(player["sprite"], imglist);
}

def drawLevel() {
    #clearVideo();
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
}

def main() {
    initGame();
    drawLevel();
    while(isKeyDown(KeyEscape) != true) {

        drawPlayer := false;

        # jump
        if(getTicks() < player["jump"]) {
            if(getTicks() > player["jumpMove"]) {
                player["y"] := player["y"] - 1;
                player["jumpMove"] := getTicks() + VERTICAL_SPEED;
                drawPlayer := true;                
            }
        } else {
            player["jump"] := 0;
            player["jumpMove"] := 0;
        }

        # gravity
        if(player["y"] < 88 && player["jump"] = 0) {
            if(getTicks() > player["gravity"]) {
                player["y"] := player["y"] + 1;
                player["gravity"] := getTicks() + VERTICAL_SPEED;
                drawPlayer := true;
            }
        } else {
            player["gravity"] := 0;
        }

        # input handling + movement
        if(anyKeyDown()) {        
            if(getTicks() > player["timer"]) {
                move := false;
                if(isKeyDown(KeyLeft) && player["x"] > 0) {
                    move := true;
                    player["flipX"] := 0;
                    player["x"] := player["x"] - 1;
                }
                if(isKeyDown(KeyRight) && player["x"] < 160) {
                    move := true;
                    player["flipX"] := 1;
                    player["x"] := player["x"] + 1;
                }
                if(isKeyDown(KeySpace) && player["jump"] = 0 && player["gravity"] = 0) {
                    player["jump"] := getTicks() + JUMP_AIR_TIME;
                }
                if(move) {
                    drawPlayer := true;
                    movePlayer();
                } else {
                    player["speed"] := SPEED_SLOW;
                    player["sinceMove"] := 0;
                }
                player["timer"] := getTicks() + player["speed"];
            }
        } else {
            # on keyup reset movement
            player["speed"] := SPEED_SLOW;
            player["sinceMove"] := 0;
            player["timer"] := 0;
        }

        if(drawPlayer) {
            drawSprite(player["x"], player["y"], player["sprite"], player["imgIndex"], player["flipX"], 0);
        }
    }
}