drops := [];

def initDrops() {
    i := 1;
    interval := 20;
    while (i < 8) {
        drops[len(drops)] := {
            "sprite": i,
            "x": interval * i,
            "y": 40,
            "w": 8,
            "h": 16,
            "timer": 0,
            "dirX": 0,
            "dirY": 1,
            "imageIndex": 0,
            "imageCount": 2,
            "speed": 0.04,
            "animationSteps": 0.2
        };
        i := i + 1;
    }
}

def moveDrops() {
     i := 0;
     while(i < len(drops)) {
        e := drops[i];
        if(getTicks() > e["timer"]) {
            e["imageIndex"] := e["imageIndex"] + e["animationSteps"];
            if(e["imageIndex"] >= e["imageCount"]) {
                e["imageIndex"] := 0;
            }
            e["timer"] := getTicks() + e["speed"];

#            # move
#            ox := e["x"];
#            oy := e["y"];
#            if(e["dirX"] != 0) {
#                e["x"] := e["x"] + e["dirX"];
#            } else {
#                e["y"] := e["y"] + e["dirY"];
#            }
#            if(checkBlocks(e["x"] - e["w"]/2, 
#                e["y"] - e["h"]/2, 
#                e["x"] + e["w"]/2, 
#                e["y"] + e["h"]/2)) {
#                e["x"] := ox;
#                e["y"] := oy;
#                e["dirX"] := e["dirX"] * -1;
#                e["dirY"] := e["dirY"] * -1;
#            }
            drawSprite(e["x"], e["y"], e["sprite"], e["imageIndex"], 0, 0);
        }
        i := i + 1;
     }
}

def checkDropCollision(playerSprite) {
    i := 0;
    while(i < len(drops)) {
        if(checkSpriteCollision(playerSprite, drops[i]["sprite"])) {
            return true;
        }
        i := i + 1;
    }
    return false;
}
