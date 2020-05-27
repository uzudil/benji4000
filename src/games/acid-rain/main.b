const SPEED_SLOW = 0.1;
const SPEED_FAST = 0.05;
const JUMP_AIR_TIME = 1;
const VERTICAL_SPEED = 0.0175;
const UP = 1;
const DOWN = 2;
const LEFT = 3;
const RIGHT = 4;
const PLAYER_WIDTH = 8;
const PLAYER_HEIGHT = 16;
const BLOCK_WIDTH = 8;
const BLOCK_HEIGHT = 16;
const DROP_WIDTH = 8;
const DROP_HEIGHT = 16;

player := {
    "sprite": 0,
    "x": 80,
    "y": 88,
    "imgIndex": 0,
    "timer": 0,
    "speed": SPEED_SLOW,
    "sinceMove": 0,
    "flipX": 0,
    "flipY": 0,
    "jump": 0,
    "jumpMove": 0,
    "gravity": 0,
    "keys": 0,
    "points": 0,
    "lives": 3,
    "death": 0,
    "deathFlip": 0,
};
img := null;
gameWon := false;
falling := false;

def animatePlayer() {
    player.sinceMove := player.sinceMove + 1;
    if(player.sinceMove > 2) {
        player.speed := SPEED_FAST;
    }
    player.imgIndex := player.imgIndex + (player.speed / SPEED_SLOW);
    if(player.imgIndex >= 4) {
        player.imgIndex := 0;
    }
}

def initGame() {
    setVideoMode(2);
    setBackground(COLOR_BLACK);
    clearVideo();

    img := load("img.dat");

    # create sprites
    setSprite(player.sprite, [img.p1, img.p2, img.p3, img.p2]);

    initDrops();
    i := 0;
    while (i < len(drops)) {
        setSprite(drops[i].sprite, [img.drop]);
        i := i + 1;
    }
}

def movePlayer(dir) {
    px := player.x;
    py := player.y;
    if(dir = UP) {
        player.y := player.y - 1;
    }
    if(dir = DOWN) {
        player.y := player.y + 1;
    }
    if(dir = LEFT) {
        player.x := player.x - 1;
        player.flipX := 0;
    }
    if(dir = RIGHT) {
        player.x := player.x + 1;
        player.flipX := 1;
    }
    if(checkBlocks(player.x - PLAYER_WIDTH/2, 
            player.y - PLAYER_HEIGHT/4, 
            player.x + PLAYER_WIDTH/2, 
            player.y + PLAYER_HEIGHT/2)) {
        player.x := px;
        player.y := py;
        return false;
    }
    return true;
}

def pickupKeys() {
    if(checkKeys(player.x - PLAYER_WIDTH/2, 
            player.y - PLAYER_HEIGHT/2, 
            player.x + PLAYER_WIDTH/2, 
            player.y + PLAYER_HEIGHT/2)) {
        player.keys := player.keys + 1;
        drawUI();
        if(player.keys >= 3) {
            openGate();
        }
    }
}

def startLevel() {
    clearVideo();
    player.x := 80;
    player.y := 88;
    player.keys := 0;
    player.lives := 3;
    drawLevel();
    drawUI();
}

def drawUI() {
    drawText(0, 190, COLOR_WHITE, COLOR_BLACK, "Lives:" + player.lives);
    drawText(90, 190, COLOR_WHITE, COLOR_BLACK, "Score:" + player.points);
    updateVideo();
}

def gameMode() {
    ox := player.x;
    oy := player.y;

    # jump
    if(getTicks() < player.jump) {
        if(getTicks() > player.jumpMove) {
            m := movePlayer(UP);
            if(m) {
                player.jumpMove := getTicks() + VERTICAL_SPEED;
            } else {
                player.jump := 0;
                player.jumpMove := 0;
            }
        }
    } else {
        player.jump := 0;
        player.jumpMove := 0;
    }

    # gravity
    if(player.jump = 0) {
        if(getTicks() > player.gravity) {
            falling := movePlayer(DOWN);
            player.gravity := getTicks() + VERTICAL_SPEED;
        }
    } else {
        player.gravity := 0;
    }

    # input handling
    if(anyKeyDown()) {        
        if(getTicks() > player.timer) {
            move := false;
            if(isKeyDown(KeyLeft)) {
                move := movePlayer(LEFT);
            }
            if(isKeyDown(KeyRight)) {
                move := movePlayer(RIGHT);
            }
            if(isKeyDown(KeySpace) && player.jump = 0 && falling = false) {
                player.jump := getTicks() + JUMP_AIR_TIME;
            }
            if(move) {
                animatePlayer();
            } else {
                player.speed := SPEED_SLOW;
                player.sinceMove := 0;
            }
            player.timer := getTicks() + player.speed;
        }
    } else {
        # on keyup reset movement
        player.speed := SPEED_SLOW;
        player.sinceMove := 0;
        player.timer := 0;
    }

    points := moveDrops();
    player.points := player.points + points;

    if(player.x != ox || player.y != oy) {
        drawSprite(player.x, player.y, player.sprite, player.imgIndex, player.flipX, 0);
        drawUI();
    }
    if(checkDropCollision(player.sprite)) {
        player.lives := player.lives - 1;
        drawUI();
        player.death := getTicks() + 1;
    }
}

def deathMode() {
    if(getTicks() < player.death) {
        if(getTicks() > player.deathFlip) {
            player.flipX := int(random() * 2);
            player.flipY := int(random() * 2);
            drawSprite(player.x, player.y, player.sprite, player.imgIndex, player.flipX, player.flipY);
            player.deathFlip := getTicks() + 0.05;
        }
    } else {
        player.death := 0;
        player.x := 80;
        player.y := 88;
    }
}

def main() {
    initGame();
    startLevel();

    while(isKeyDown(KeyEscape) != true && gameWon = false && player.lives > 0) {

        if(player.death > 0) {
            deathMode();
        } else {
            gameMode();
        }
    }
}
