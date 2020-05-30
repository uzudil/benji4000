const SPEED = 0.015;
const ANIM_STEPS = 0.2;
const WIDTH = 30;
const HEIGHT = 20;
const BLOCK_W = 8;
const BLOCK_H = 16;
const SCREEN_W = int(160/BLOCK_W)*BLOCK_W;
const SCREEN_H = int(200/BLOCK_H)*BLOCK_H;
const EMPTY = -1;
const ICE = 0;
const ROCK = 1;
const BRICK = 2;
const IMG = [ "ice", "rock", "brick" ];
const ROCK_FALL_SPEED = 0.015;
const DEBUG = false;

player := {
    "x": WIDTH/2 * BLOCK_W,
    "y": HEIGHT/2 * BLOCK_H,
    "flipX": 0,
    "flipY": 0,
    "moveX": 0,
    "moveY": 0,
    "imgIndex": 0,
    "sprite": 0,
    "timer": 0,
    "draw": self => {
        if(self.moveX = 1) {
            self.flipX := 1;
        } else {
            self.flipX := 0;
        }
        drawSprite(SCREEN_W/2 + BLOCK_W/2, SCREEN_H/2 + BLOCK_H/2, self.sprite, self.imgIndex, self.flipX, self.flipY);
        self.imgIndex := self.imgIndex + ANIM_STEPS;
        if(self.imgIndex >= 4) {
            self.imgIndex := 0;
        }
    },
    "getBlock": (self, dx, dy) => {
        bx := int((self.x + dx) / BLOCK_W + 0.5);
        by := int((self.y + dy) / BLOCK_H + 0.5);
        return room.blocks[bx][by].block;
    },
    "move": self => {
        deltaX := self.x % BLOCK_W;
        deltaY := self.y % BLOCK_H;

        if(isKeyDown(KeyLeft)) {
            self.moveX := -1;
        }
        if(isKeyDown(KeyRight)) {
            self.moveX := 1;
        }

        if(isKeyDown(KeyUp)) {
            self.moveY := -1;
        }
        if(isKeyDown(KeyDown)) {
            self.moveY := 1;
        }

        ret := false;
        if(getTicks() > self.timer) {
            
            if(self.moveX != 0) {
                delta := BLOCK_W/2;
                if(self.moveX = -1) {
                    delta := -1 * (BLOCK_W/2 + 1);
                }
                if(self.getBlock(delta, BLOCK_H * -0.4) = ROCK || self.getBlock(delta, BLOCK_H * -0.4) = BRICK || 
                    self.getBlock(delta, BLOCK_H * 0.4) = ROCK || self.getBlock(delta, BLOCK_H * 0.4) = BRICK || 
                    (isKeyDown(KeyLeft) = false && isKeyDown(KeyRight) = false && deltaX = 0)) {
                    self.moveX := 0;
                } else {
                    self.x := self.x + self.moveX;
                }
            }
            if(self.moveY != 0) {
                delta := BLOCK_H/2;
                if(self.moveY = -1) {
                    delta := -1 * (BLOCK_H/2 + 1);
                }
                if(self.getBlock(BLOCK_W * -0.4, delta) = ROCK || self.getBlock(BLOCK_W * -0.4, delta) = BRICK || 
                    self.getBlock(BLOCK_W * 0.4, delta) = ROCK || self.getBlock(BLOCK_W * 0.4, delta) = BRICK || 
                    (isKeyDown(KeyUp) = false && isKeyDown(KeyDown) = false && deltaY = 0)) {
                    self.moveY := 0;
                } else {
                    self.y := self.y + self.moveY;
                }                
            }

            if(self.moveY != 0 || self.moveX != 0) {
                bx := int(self.x/BLOCK_W+0.5);
                by := int(self.y/BLOCK_H+0.5);
                room.blocks[bx][by].block := EMPTY;
                if(room.blocks[bx][by-1].block = ROCK) {
                    room.startFalling(bx, by - 1);
                }
                self.draw();
                ret := true;
            }

            self.timer := getTicks() + SPEED;
        }
        return ret;
    },
};

room := {
    "blocks": [],
    "willfall": [],
    "falling": [],
    "timer": 0,
    "init": self => {
        x := 0;
        while(x < WIDTH) {
            self.blocks[x] := [];
            y := 0;
            while(y < HEIGHT) {
                block := int(random() * 2);
                if(x = 0 || x = WIDTH - 1 || y = 0 || y = HEIGHT - 1) {
                    block := BRICK;
                }
                if(abs(player.x/BLOCK_W - x) <= 2 && abs(player.y/BLOCK_H - y) <= 2) {
                    block := ICE;
                }                
                self.blocks[x][y] := {
                    "block": block,
                    "dy": 0
                };
                y := y + 1;
            }
            x := x + 1;
        }
    },
    "draw": self => {
        sx := (player.x - SCREEN_W/2)/BLOCK_W;
        ex := sx + SCREEN_W/BLOCK_W + 1;
        sy := (player.y-SCREEN_H/2)/BLOCK_H;
        ey := sy + SCREEN_H/BLOCK_H + 1;
        clearVideo();
        dx := player.x % BLOCK_W;
        dy := player.y % BLOCK_H;
        x := 0;
        while(x < ex - sx) {
            bx := sx + x;
            if(bx >= 0 && bx < WIDTH) {
                y := 0;
                while(y < ey - sy) {
                    by := sy + y;
                    if(by >= 0 && by < HEIGHT) {
                        block := self.blocks[bx][by];
                        if(block.block >= 0 && block.block < len(IMG)) {
                            drawImage(x * BLOCK_W - dx, y * BLOCK_H - dy + block.dy, img[IMG[block.block]]);
                        }
                        if(DEBUG && int(bx) = int(player.x/BLOCK_W + 0.5) && int(by) = int(player.y/BLOCK_H + 0.5)) {
                            drawRect(x * BLOCK_W - dx, y * BLOCK_H - dy, (x + 1) * BLOCK_W - dx, (y + 1) * BLOCK_H - dy, COLOR_RED);
                        }
                    }
                    y := y + 1;
                }
            }
            x := x + 1;
        }
        fillRect(0, SCREEN_H, 160, 200, COLOR_BLACK);
        deltaX := player.x % BLOCK_W;
        deltaY := player.y % BLOCK_H;
        drawText(0, SCREEN_H, COLOR_WHITE, COLOR_BLACK, deltaX + "," + deltaY);
        updateVideo();
    },
    "startFalling": (self, bx, by) => {
        i := 0;
        while(i < len(self.willfall)) {
            if(self.willfall[i][0] = bx && self.willfall[i][1] = by) {
                return false;
            }
            i := i + 1;
        }
        self.willfall[len(self.willfall)] := [bx, by, getTicks() + 0.5];
        return true;
    },
    "moveRocks": self => {
        ret := false;
        if(getTicks() > self.timer && (len(self.falling) > 0 || len(self.willfall) > 0)) {

            i := 0;
            while(i < len(self.willfall)) {
                if(getTicks() > self.willfall[i][2]) {
                    self.falling[len(self.falling)] := [self.willfall[i][0], self.willfall[i][1]];
                    del self.willfall[i];
                } else {
                    i := i + 1;
                }
            }

            i := 0;
            while(i < len(self.falling)) {
                bx := self.falling[i][0];
                by := self.falling[i][1];

                if(self.blocks[bx][by].dy = 0 && self.blocks[bx][by + 1].block != EMPTY) {
                    del self.falling[i];
                } else {
                    # move rock
                    self.blocks[bx][by].dy := self.blocks[bx][by].dy + 1;

                    # transfer to next block
                    if(self.blocks[bx][by].dy >= BLOCK_H/2) {
                        if(self.blocks[bx][by - 1].block = ROCK) {
                            self.startFalling(bx, by - 1);
                        }
                        self.blocks[bx][by] := {
                            "block": EMPTY,
                            "dy": 0
                        };
                        self.blocks[bx][by + 1] := {
                            "block": ROCK,
                            "dy": BLOCK_H / -2
                        };
                        self.falling[i][1] := by + 1;
                    }

                    i := i + 1;
                }
            }            
            ret := true;
            self.timer := getTicks() + ROCK_FALL_SPEED;
        }
        return ret;
    }
};
img := null;

def main() {
    setVideoMode(2);

    # ice blue
    setColor(COLOR_LIGHT_BLUE, 216, 216, 255);

    setBackground(COLOR_LIGHT_BLUE);
    clearVideo();

    img := load("img.dat");

    # create sprites
    setSprite(player.sprite, [img["p1"], img["p3"], img["p2"], img["p3"] ]);

    room.init();
    room.draw();
    player.draw();

    while(true) {
        a := player.move();
        b := room.moveRocks();
        if(a || b) {
            room.draw();
        }
    }
}
