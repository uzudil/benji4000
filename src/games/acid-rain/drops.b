
drops := [];

def initDrops() {
    i := 0;
    while (i < 7) {
        snum := i + 1;
        start_x := snum * 20;
        start_y := 40;
        drops[i] := {
            "sprite": snum,
            "start_x": start_x,
            "x": start_x,
            "start_y": start_y,
            "y": start_y,
            "w": 8,
            "h": 16,
            "timer": 0,
            "choice_timer": 0,
            "choice_speed": random(),
            "dirX": 0,
            "dirY": 1,
            "imageIndex": 0,
            "imageCount": 1,
            "speed": 0.04,
            "animationSteps": 0.2,
            "active": canDrop()
        };
        i := i + 1;
    }
}

def canDrop() {
    n := int(random() * 10) % 2;
    return n;
}

def moveDrops() {
     points := 0;
     i := 0;
     while(i < len(drops)) {
        e := drops[i];
        if (getTicks() > e.choice_timer) {
            if (e.active = 0) {
                e.active := canDrop();
            }
            e.choice_timer := getTicks() + e.choice_speed;
            e.choice_speed := random();
        }
        if(getTicks() > e.timer) {
            e.imageIndex := e.imageIndex + e.animationSteps;
            if(e.imageIndex >= e.imageCount) {
                e.imageIndex := 0;
            }
            e.timer := getTicks() + e.speed;

            # move
            if (e.active = 1) {
                if(e.dirX != 0) {
                    e.x := e.x + e.dirX;
                } else {
                    e.y := e.y + e.dirY;
                }
                if(checkBlocks(e.x - e.w/2, 
                    e.y - e.h/2, 
                    e.x + e.w/2, 
                    e.y + e.h/2)) {
                    e.active := 0;
                    e.x := e.start_x;
                    e.y := e.start_y;
                    if ((random() * 100) % 3 = 0) {
                        e.speed := e.speed + (random() * .01);
                    } else {
                        e.speed := e.speed - (random() * .01);
                    }
                    points := points + 1;
                }
            }
            drawSprite(e.x, e.y, e.sprite, e.imageIndex, 0, 0);
        }
        i := i + 1;
     }
     return points;
}

def checkDropCollision(playerSprite) {
    i := 0;
    while(i < len(drops)) {
        if(checkSpriteCollision(playerSprite, drops[i].sprite)) {
            return true;
        }
        i := i + 1;
    }
    return false;
}
