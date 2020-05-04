player := {
    "x": 160,
    "y": 190,
    "size": 40
};

const NE = 0;
const NW = 1;
const SW = 2;
const SE = 3;

ball := {
    "x": 160,
    "y": 100,
    "dir": NE
};

const START_SPEED = 0.03;
const START_SPEED_PLAYER = 0.05;

ball_speed := START_SPEED;
speed := START_SPEED_PLAYER;
score := 0;
lives := 3;
fail_time := 0;

def movePlayer() {
    if(isKeyDown(KeyLeft)) {
        if(player["x"] > 0) {
            player["x"] := player["x"] - speed;
        }
    }
    if(isKeyDown(KeyRight)) {
        if(player["x"] < 320 - player["size"]) {
            player["x"] := player["x"] + speed;
        }
    }
}

def moveBall() {
    if(ball["dir"] = NE) {
        ball["x"] := ball["x"] + ball_speed;
        ball["y"] := ball["y"] - ball_speed;
    }
    if(ball["dir"] = NW) {
        ball["x"] := ball["x"] - ball_speed;
        ball["y"] := ball["y"] - ball_speed;
    }
    if(ball["dir"] = SE) {
        ball["x"] := ball["x"] + ball_speed;
        ball["y"] := ball["y"] + ball_speed;
    }
    if(ball["dir"] = SW) {
        ball["x"] := ball["x"] - ball_speed;
        ball["y"] := ball["y"] + ball_speed;
    }
    if(ball["x"] < 10) {
        if(ball["dir"] = SW) {
            ball["dir"] := SE;
        } else {
            ball["dir"] := NE;
        }
    }
    if(ball["x"] >= 310) {
        if(ball["dir"] = SE) {
            ball["dir"] := SW;
        } else {
            ball["dir"] := NW;
        }
    }
    if(ball["y"] < 10) {
        if(ball["dir"] = NW) {
            ball["dir"] := SW;
        } else {
            ball["dir"] := SE;
        }
    }
    if(ball["y"] >= 190) {
        handled := 0;
        if(ball["x"] >= player["x"]) {
            if(ball["x"] < player["x"] + player["size"]) {
                if(ball["dir"] = SE) {
                    ball["dir"] := NE;
                } else {
                    ball["dir"] := NW;
                }
                handled := 1;
                score := score + 1;
                if(score % 2 = 0) {
                    ball_speed := ball_speed * 1.5;
                    speed := speed * 1.5;
                }
            }
        }
        if(handled = 0) {
            lives := lives - 1;
            fail_time := getTicks() + 2;
        }
    }
}

def reset() {
    fail_time := 0;
    ball_speed := START_SPEED;
    speed := START_SPEED_PLAYER;
    ball["x"] := 160;
    ball["y"] := 100;
    ball["dir"] := NE;
}

def main() {
    setVideoMode(1);

    while(1=1) {
        clearVideo();

        if(lives > 0) {
            if(fail_time != 0) {
                if(getTicks() < fail_time) {
                    fillCircle(ball["x"], ball["y"], 10, random() * 16);
                } else {
                    reset();
                }
            } else {
                fillCircle(ball["x"], ball["y"], 10, COLOR_RED);
            }
            fillRect(player["x"], player["y"], player["x"] + player["size"], player["y"] + 10, COLOR_DARK_BROWN);
            drawText(10, 0, COLOR_BLACK, COLOR_LIGHT_BLUE, "Score: " + score);
            drawText(200, 0, COLOR_BLACK, COLOR_LIGHT_BLUE, "Lives: " + lives);

            if(fail_time = 0) {
                movePlayer();
                moveBall();
            }
        } else {
            drawRect(100, 80, 220, 112, COLOR_RED);
            drawText(125, 93, COLOR_RED, COLOR_LIGHT_BLUE, "Game Over");
        }

        updateVideo();
    }
}
