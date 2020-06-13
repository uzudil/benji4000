const ROTOR = [ 10, 7, 5, 3 ];
const GROUND_STEP = 4;
const SPEED = 0.01;
const SPEED_FUEL = 0.05;
const SPEED_FUEL_DOWN = 0.2;
const SPEED_Y = 0.0001;
const WAIVE_SPEED = 0.15;
const GRAVITY_SPEED = 0.01;
const MAX_HEIGHT = 85;
const GROUND_HEIGHT_STEP = 2;
const WAIVE = [ 3, 2, 1, 2 ];
const HIT_NOTHING = 0;
const HIT_GROUND = 1;
const HIT_PAD = 2;
const PLAYER_COLOR = COLOR_TAN;

# todo: can't place comments inside map literal
player := {
    "x": 30 * GROUND_STEP, 
    "y": 100,
    "dir": 0,
    "rotor": 0,
    "switch": 0,
    "dirchange": 0,
    "move": 0,
    "moveY": 0,
    "explode": 0,
    "lives": 5,
    "gravity_enabled": true,
    "fuel": 100,
    "fuelTimer": -1,
    "carry": 0,
    "saved": 0,
    "killed": 0,
    "updowntimer": 0
};
title := true;
info := true;
ground := [];
groundIndex := 0;    
scrollStep := 0;
turnDir := 0;
soldiers := [ 
    330 * GROUND_STEP, 
    331 * GROUND_STEP, 
    334 * GROUND_STEP, 
    630 * GROUND_STEP, 
    627 * GROUND_STEP, 
    930 * GROUND_STEP, 
    932 * GROUND_STEP, 
    928 * GROUND_STEP 
];
soldierMoveTimer := 0;
waiveTimer := 0;
waiveIndex := 0;

def handleInput() {
    if(player.explode > 0) {
        # todo: return must always return a value...
        return false;
    }
    if(isKeyDown(KeyLeft)) {
        if(turnDir != -1) {
            player.dirchange := 0;
        }
        turnDir := -1;
    } else {
        if(isKeyDown(KeyRight)) {
            if(turnDir != 1) {
                player.dirchange := 0;
            }
            turnDir := 1;
        } else {
            turnDir := 0;
        }
    }
    if(getTicks() > player.updowntimer) {
        if(isKeyDown(KeyUp) && player.y > 10 && player.fuel > 0) {
            player.y := player.y - 1;
        }
        if(isKeyDown(KeyDown)) {
            player.y := player.y + 1;
        }
        player.updowntimer := getTicks() + SPEED_Y;
    }

    if(getTicks() > player.dirchange) {
        if(turnDir = -1 && player.dir > -1) {
            player.dir := player.dir - 1;
        }
        if(turnDir = 1 &&  player.dir < 1) {
            player.dir := player.dir + 1;
        }
        player.dirchange := getTicks() + 0.15;
    }
}

def movePlayer() {
    if(player.explode = 0 && getTicks() > player.moveY && player.gravity_enabled) {
        player.moveY := getTicks() + GRAVITY_SPEED;

        # gravity
        player.y := player.y + 1;
    }

    if(getTicks() > player.fuelTimer) {
        if(player.gravity_enabled) {
            if(player.fuel > 0) {
                player.fuel := player.fuel - 1;
            }
            player.fuelTimer := getTicks() + SPEED_FUEL_DOWN;
        }
        if(player.gravity_enabled = false) {
            if(player.fuel < 100) {
                player.fuel := player.fuel + 1;
            }
            player.fuelTimer := getTicks() + SPEED_FUEL;
        }
    }

    if(player.dir != 0 && getTicks() > player.move) {
        player.move := getTicks() + SPEED;

        handled := false;
        if(player.dir = 1 && player.x < 80) {
            player.x := player.x + 1;
            handled := true;
        }
        if(player.dir = -1 && player.x > 80) {
            player.x := player.x - 1;
            handled := true;
        }

        if(handled = false) {
            if(canScroll()) {
                scrollStep := scrollStep - player.dir*2;
                if(scrollStep >= GROUND_STEP) {
                    scrollStep := 0;
                    groundIndex := groundIndex - 1;
                }
                if(scrollStep <= -1) {
                    scrollStep := GROUND_STEP - 2;
                    groundIndex := groundIndex + 1;
                }                
            } else {
                if(player.x < 160 && player.x > 0) {
                    player.x := player.x + player.dir;
                }
            } 
        }
    }    
}

def testCollision() {
    if(player.dir = 0) {
        sx := player.x - 5;
        ex := player.x + 5;
    }
    if(player.dir = 1) {
        sx := player.x - 12;
        ex := player.x + 5;
    }
    if(player.dir = -1) {
        sx := player.x - 5;
        ex := player.x + 12;
    }
    sy := player.y - 10;
    ey := player.y + 5;
    while(sx < ex) {
        while(sy < ey) {
            gi := groundIndex + sx / GROUND_STEP;
            if(gi >= 0 && gi < len(ground)) {
                if(ground[gi].pad > -1 && sy > 200 - ground[gi].pad) {
                    return HIT_PAD;
                } else {
                    groundHeight := ground[gi].height;
                    if(sy > 200 - groundHeight) {
                        return HIT_GROUND;
                    }
                }
            }
            sy := sy + GROUND_HEIGHT_STEP;
        }
        sx := sx + GROUND_STEP;
    }
    return HIT_NOTHING;
}

def drawPlayerExplode() {
    i := 0;
    while(i < 10) {
        if(random() > 0.5) {
            color := COLOR_YELLOW;
        } else {
            color := COLOR_WHITE;
        }
        fillCircle(player.x - 5 + (random() * 10), player.y - 5 + (random() * 10), random() * 10 + 3, color);
        i := i + 1;
    }
}

def drawPlayerHealthy() {
    # todo: use a sprite instead?
    fillCircle(player.x, player.y, 5, PLAYER_COLOR);
    if(player.dir = 0) {
        fillRect(player.x-3, player.y-2, player.x+3, player.y, COLOR_WHITE);
    }
    if(player.dir = 1) {
        fillRect(player.x, player.y-2, player.x+3, player.y, COLOR_WHITE);
        fillRect(player.x - 12, player.y - 5, player.x, player.y, PLAYER_COLOR);
        fillRect(player.x - 12, player.y - 7, player.x-10, player.y-5, PLAYER_COLOR);
    }
    if(player.dir = -1) {
        fillRect(player.x-3, player.y-2, player.x, player.y, COLOR_WHITE);
        fillRect(player.x, player.y - 5, player.x+12, player.y, PLAYER_COLOR);
        fillRect(player.x+10, player.y - 7, player.x+12, player.y-5, PLAYER_COLOR);
    }
    fillRect(player.x-1, player.y-10, player.x+1, player.y, PLAYER_COLOR);

    # animate the rotor
    if(getTicks() > player.switch) {
        if(player.gravity_enabled) {
            player.rotor := player.rotor + 1;
            if (player.rotor >= len(ROTOR)) {
                player.rotor := 0;
            }
        } else {
            player.rotor := 0;
        }
        player.switch := getTicks() + 0.025;
    }
    fillRect(player.x-ROTOR[player.rotor], player.y-7, player.x+ROTOR[player.rotor], player.y-10, PLAYER_COLOR);
}

def drawPlayer() {
    if(player.explode > getTicks()) {
        drawPlayerExplode();
    } else {        
        if(player.explode > 0) {
            # reset player
            player.lives := player.lives - 1;
            player.y := 100;
            player.explode := 0;
            player.fuel := 100;
            player.killed := player.killed + player.carry;
            player.carry := 0;
            i := 0; 
            while(i < len(soldiers)) {
                if(soldiers[i] = -1000) {
                    del soldiers[i];
                } else {
                    i := i + 1;
                }
            }
        } else {
            # collision check
            collision := testCollision();
            if(collision = HIT_GROUND) {
                player.explode := getTicks() + 1.5;
                player.dir := 0;
            }
            if(collision = HIT_PAD && player.y >= 200 - MAX_HEIGHT - 5) {
                player.gravity_enabled := false;
            } else {
                player.gravity_enabled := true;
            }
        }
        drawPlayerHealthy();
    }
}

def initGround() {
    length := 1000;
    h := random() * MAX_HEIGHT;
    while(len(ground) < length) {
        g := { "height": h };
        putPad := len(ground) % 300;
        if(putPad >= 25 && putPad < 35) {
            padHeight := h;
            if(len(ground) > 0 && ground[len(ground) - 1].pad > -1) {
                padHeight := ground[len(ground) - 1].pad;
            }
            g.pad := padHeight;            
            g.height := 0;
        } else {
            g.pad := -1;
        }
        ground[len(ground)] := g;
        if(random() > 0.5) {
            if(h < MAX_HEIGHT) {
                h := h + GROUND_HEIGHT_STEP;
            }
        } else {
            if(h > 4) {
                h := h - GROUND_HEIGHT_STEP;
            }
        }
    }    
}

def canScroll() {
    if(player.dir = 1 && groundIndex >= len(ground) - (160/GROUND_STEP) - 1) {
        return false;
    }
    if(player.dir = -1 && groundIndex <= 1) {
        return false;
    }
    return true;
}

def drawSoldier(index, x, y) {
    if(getTicks() > waiveTimer) {
        waiveTimer := getTicks() + WAIVE_SPEED;
        waiveIndex := waiveIndex + 1;
        if(waiveIndex >= len(WAIVE)) {
            waiveIndex := 0;
        }
    }
    wi := (waiveIndex + index) % len(WAIVE);
    drawLine(x + WAIVE[wi], y - 10, x + 4, y - 4, COLOR_LIGHT_BLUE);
    drawLine(x + 8 - WAIVE[wi], y - 10, x + 4, y - 4, COLOR_LIGHT_BLUE);
    fillRect(x + 3, y - 8, x + 5, y - 5, COLOR_LIGHT_BLUE);
    fillRect(x + 2, y - 4, x + 3, y, COLOR_LIGHT_BLUE);
    fillRect(x + 5, y - 4, x + 6, y, COLOR_LIGHT_BLUE);
}

def drawGround() {
    x := 0; 
    if(scrollStep > 0) {
        x := -1 * GROUND_STEP;
    }
    sx := x;
    while(x < 160) {
        gi := groundIndex + x/GROUND_STEP;

        if(ground[gi].pad > -1) {
            h := 200 - ground[gi].pad;
            if(gi = 25) {
                # draw the flag
                drawLine(x - 3, h - 18, x - 3, h, COLOR_LIGHT_GRAY);
                drawLine(x - 2, h - 18, x + 5, h - 18, COLOR_RED);
                drawLine(x - 2, h - 17, x + 5, h - 17, COLOR_WHITE);
                drawLine(x - 2, h - 16, x + 5, h - 16, COLOR_RED);
                drawLine(x - 2, h - 15, x + 5, h - 15, COLOR_WHITE);
                drawLine(x - 2, h - 14, x + 5, h - 14, COLOR_RED);
                drawLine(x - 2, h - 13, x + 5, h - 13, COLOR_WHITE);
                drawLine(x - 2, h - 12, x + 5, h - 12, COLOR_RED);
                fillRect(x - 2, h - 18, x + 2, h - 14, COLOR_LIGHT_BLUE);
                # draw the house
                drawLine(x - 2, h - 5, x + 4, h - 8, COLOR_BROWN);
                drawLine(x + 4, h - 8, x + 10, h - 5, COLOR_BROWN);
                fillRect(x, h - 6, x + 8, h, COLOR_BROWN);
                fillRect(x + 3, h - 7, x + 6, h - 6, COLOR_BROWN);
                fillRect(x + 3, h - 5, x + 5, h - 2, COLOR_YELLOW);
            }
            fillRect(x + scrollStep, h, x + scrollStep + GROUND_STEP, 200, COLOR_DARK_GRAY);
        } else {        
            fillRect(x + scrollStep, 200 - ground[gi].height, x + scrollStep + GROUND_STEP, 200, COLOR_GREEN);
        }

        x := x + GROUND_STEP;
    }
    i := 0;
    while(i < len(soldiers)) {
        if(soldiers[i] >= groundIndex * GROUND_STEP && soldiers[i] < groundIndex * GROUND_STEP + 160) {
            drawSoldier(
                i,
                soldiers[i] - groundIndex * GROUND_STEP, 
                200 - ground[soldiers[i] / GROUND_STEP].pad
            );
        }
        i := i + 1;
    }
}

def moveSoldiers() {
    # move soldiers towards nearby landed chopper
    if(player.gravity_enabled = false && getTicks() > soldierMoveTimer) {
        i := 0;
        while(i < len(soldiers)) {
            if(soldiers[i] = -1000 && groundIndex < 300) {
                # exit chopper
                soldiers[i] := (25 + random() * 10) * GROUND_STEP;
                player.carry := player.carry - 1;
                player.saved := player.saved + 1;
            } else {
                # need to be saved
                if(soldiers[i] > 300 && player.carry < 4) {
                    sx := soldiers[i] - groundIndex * GROUND_STEP;
                    d := sx - player.x;
                    if(abs(d) < 10 * GROUND_STEP) {
                        if(abs(d) < GROUND_STEP) {
                            # enter chopper
                            player.carry := player.carry + 1;
                            soldiers[i] := -1000;
                        } else {
                            # move towards chopper
                            if(d < 0) {
                                soldiers[i] := soldiers[i] + 0.1;
                            } else {
                                soldiers[i] := soldiers[i] - 0.1;
                            }
                        }
                    }                    
                }
            }
            i := i + 1;
        }
        soldierMoveTimer := getTicks() + 0.01;
    }
}

def drawUI() {
    drawText(0, 0, COLOR_LIGHT_BLUE, COLOR_DARK_BLUE, "FUEL:");
    color := COLOR_GREEN;
    if(player.fuel < 50) {
        color := COLOR_YELLOW;
    }
    if(player.fuel < 20) {
        color := COLOR_RED;
    }
    fillRect(40, 3, 40 + (160 - 44) * (player.fuel/100), 5, color);
    drawText(0, 10, COLOR_LIGHT_BLUE, COLOR_DARK_BLUE, "LIFE:" + player.lives);
    drawText(160 - 70 - 2, 10, COLOR_LIGHT_BLUE, COLOR_DARK_BLUE, "CARRY:" + player.carry + "/4");
}

def drawTitle() {
    drawRect(5, 5, 155, 195, COLOR_DARK_BLUE);
    drawText(50, 20, COLOR_BROWN, COLOR_BLACK, "Airwolf");
    drawText(14, 35, COLOR_MID_GRAY, COLOR_BLACK, "for the Benji4000");
    drawText(25, 160, COLOR_MID_GRAY, COLOR_BLACK, "SPACE to start");
    drawText(14, 175, COLOR_DARK_GRAY, COLOR_BLACK, "2020 (c) by Gabor");
    player.x := 80;
    player.y := 100;
    player.dir := -1;
    drawPlayerHealthy();
    if(isKeyDown(KeySpace)) {
        player.x := 30 * GROUND_STEP;
        player.y := 100;
        player.dir := 0;
        title := false;
        while(isKeyDown(KeySpace)) {
        }
    }
}

def drawInfo() {
    drawRect(5, 5, 155, 195, COLOR_DARK_BLUE);
    drawText(50, 20, COLOR_BROWN, COLOR_BLACK, "Airwolf");
    drawText(14, 45, COLOR_MID_GRAY, COLOR_BLACK, "Rescue soldiers");
    drawText(14, 55, COLOR_MID_GRAY, COLOR_BLACK, "stranded behind");
    drawText(14, 65, COLOR_MID_GRAY, COLOR_BLACK, "enemy lines.");

    drawText(14, 85, COLOR_MID_GRAY, COLOR_BLACK, "Watch that you");
    drawText(14, 95, COLOR_MID_GRAY, COLOR_BLACK, "don't run out");
    drawText(14, 105, COLOR_MID_GRAY, COLOR_BLACK, "of fuel.");

    drawText(14, 125, COLOR_MID_GRAY, COLOR_BLACK, "Good luck! Press");
    drawText(14, 135, COLOR_MID_GRAY, COLOR_BLACK, "SPACE to begin");
    if(isKeyDown(KeySpace)) {
        player.x := 30 * GROUND_STEP;
        player.y := 100;
        player.dir := 0;
        setBackground(COLOR_DARK_BLUE);
        info := false;
    }
}

def main() {
    setVideoMode(2);
    setBackground(COLOR_BLACK);
    initGround();
    
    while(1=1) {
        clearVideo();
        if(title) {
            drawTitle();
        } else {
            if(info) {
                drawInfo();
            } else {
                if(player.lives > 0) {        
                    if(player.saved < len(soldiers)) {
                        handleInput();
                        movePlayer();
                        moveSoldiers();
                        drawGround();
                        drawPlayer();
                        drawUI();
                    } else {
                        fillRect(40, 60, 120, 140, COLOR_GREEN);
                        drawText(45, 87, COLOR_BLACK, COLOR_GREEN, "Congrats!");
                        if(player.killed = 0) {
                            drawText(45, 97, COLOR_BLACK, COLOR_GREEN, "Game Won!");
                        } else {
                            drawText(45, 97, COLOR_BLACK, COLOR_GREEN, "Killed: " + player.killed);
                            drawText(45, 107, COLOR_BLACK, COLOR_GREEN, "Saved: " + player.saved);
                        }
                    }
                } else {
                    fillRect(40, 60, 120, 140, COLOR_YELLOW);
                    drawText(45, 94, COLOR_BLACK, COLOR_YELLOW, "Game Over");
                }
            }
        }
        updateVideo();
    }
}
