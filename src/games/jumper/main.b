const SPEED_SLOW = 0.1;
const SPEED_FAST = 0.05;
const JUMP_AIR_TIME = 0.6;
const VERTICAL_SPEED = 0.0175;
const UP = 1;
const DOWN = 2;
const LEFT = 3;
const RIGHT = 4;
const PLAYER_WIDTH = 16;
const PLAYER_HEIGHT = 24;
const BLOCK_WIDTH = 8;
const BLOCK_HEIGHT = 16;

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
roomIndex := 0;
blocks := [];

def animatePlayer() {
    player["sinceMove"] := player["sinceMove"] + 1;
    if(player["sinceMove"] > 2) {
        player["speed"] := SPEED_FAST;
    }
    player["imgIndex"] := player["imgIndex"] + (player["speed"] / SPEED_SLOW);
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
    room := rooms[roomIndex];
    blocks := [];
    row := 0; 
    while(row < len(room)) {
        x := 0;
        while(x < len(room[row])) {
            c := substr(room[row], x, 1);
            if(c = "x") {
                drawImage(x * BLOCK_WIDTH, row * BLOCK_HEIGHT, img["b1"]);
                blocks[len(blocks)] := [
                    x * BLOCK_WIDTH, row * BLOCK_HEIGHT,
                    (x + 1) * BLOCK_WIDTH, (row + 1) * BLOCK_HEIGHT
                ];
            }
            x := x + 1;
        }
        row := row + 1;
    }
    updateVideo();
}

# todo: implement in go with quad-tree
def checkBlocks() {
    i := 0;
    while(i < len(blocks)) {
        if(isOverlap(
            player["x"] - PLAYER_WIDTH/2, 
            player["y"] - PLAYER_HEIGHT/2, 
            player["x"] + PLAYER_WIDTH/2, 
            player["y"] + PLAYER_HEIGHT/2, 
            blocks[i][0],
            blocks[i][1],
            blocks[i][2],
            blocks[i][3])
        ) {
            return true;
        }
        i := i + 1;
    }
    return false;
}

def movePlayer(dir) {
    px := player["x"];
    py := player["y"];
    if(dir = UP) {
        player["y"] := player["y"] - 1;
    }
    if(dir = DOWN) {
        player["y"] := player["y"] + 1;
    }
    if(dir = LEFT) {
        player["x"] := player["x"] - 1;
    }
    if(dir = RIGHT) {
        player["x"] := player["x"] + 1;
    }
    if(checkBlocks()) {
        player["x"] := px;
        player["y"] := py;
        return false;
    }
    return true;
}

def main() {
    initGame();
    drawLevel();
    first := true;
    falling := false;
    while(isKeyDown(KeyEscape) != true) {

        drawPlayer := first;
        first := false;
        # jump
        if(getTicks() < player["jump"]) {
            if(getTicks() > player["jumpMove"]) {
                drawPlayer := movePlayer(UP);
                player["jumpMove"] := getTicks() + VERTICAL_SPEED;
            }
        } else {
            player["jump"] := 0;
            player["jumpMove"] := 0;
        }

        # gravity
        if(player["jump"] = 0) {
            if(getTicks() > player["gravity"]) {
                drawPlayer := movePlayer(DOWN);
                falling := drawPlayer;
                player["gravity"] := getTicks() + VERTICAL_SPEED;
            }
        } else {
            player["gravity"] := 0;
        }

        # input handling + movement
        if(anyKeyDown()) {        
            if(getTicks() > player["timer"]) {
                move := false;
                if(isKeyDown(KeyLeft)) {
                    move := movePlayer(LEFT);
                    player["flipX"] := 0;
                }
                if(isKeyDown(KeyRight)) {
                    move := movePlayer(RIGHT);
                    player["flipX"] := 1;
                }
                if(isKeyDown(KeySpace) && player["jump"] = 0 && falling = false) {
                    player["jump"] := getTicks() + JUMP_AIR_TIME;
                }
                if(move) {
                    drawPlayer := true;
                    animatePlayer();
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