enemies := {
    "butterfly": { "images": [ "en1", "en2" ], "w": 8,  "h": 16 },
    "biter": { "images": [ "en3", "en4" ], "w": 8,  "h": 16 },
};

enemyDefaults := {
    "images": null,
    "x": 0,
    "y": 0,
    "dirX": 0,
    "dirY": 0,
    "timer": 0,    
    "imageCount": 0,
    "imageIndex": 0,
    "speed": 0.04,
    "animationSteps": 0.2
};

perRoom := [
    [
        [ "butterfly", 40, 40, 0, 1],
        [ "butterfly", 80, 165, 1, 0]
    ],
    [
        [ "biter", 80, 40, 1, 0],
        [ "biter", 80, 140, 1, 0],
        [ "biter", 120, 30, 0, 1]
    ]
];

enemyInstances := [];

def initEnemies() {
    # remove old sprites + data
    i := 0;
    while(i < len(enemyInstances)) {
        delSprite(enemyInstances[i].sprite);
        i := i + 1;
    }
    enemyInstances := [];

    # add new sprites + data
    i := 0;
    enemyList := perRoom[roomIndex];
    while(i < len(enemyList)) {
        e := {};

        # default settings
        defaultKeys := keys(enemyDefaults);
        k := 0;
        while(k < len(defaultKeys)) {
            theKey := defaultKeys[k];
            e[theKey] := enemyDefaults[theKey];
            k := k + 1;
        }

        # per room settings
        e.x := enemyList[i][1];
        e.y := enemyList[i][2];
        e.dirX := enemyList[i][3];
        e.dirY := enemyList[i][4];

        # class defaults
        enemyDef := enemies[enemyList[i][0]];
        e.w := enemyDef.w;
        e.h := enemyDef.h;

        imageList := [];
        ii := 0;
        e.imageCount := len(enemyDef.images);
        while(ii < len(enemyDef.images)) {
            imageList[ii] := img[enemyDef.images[ii]];
            ii := ii + 1;
        }
        e.sprite := i + 1;
        setSprite(e.sprite, imageList);

        enemyInstances[i] := e;
        i := i + 1;
    }
}

def moveEnemies() {
     i := 0;
     while(i < len(enemyInstances)) {
        e := enemyInstances[i];
        if(getTicks() > e.timer) {
            e.imageIndex := e.imageIndex + e.animationSteps;
            if(e.imageIndex >= e.imageCount) {
                e.imageIndex := 0;
            }
            e.timer := getTicks() + e.speed;

            # move
            ox := e.x;
            oy := e.y;
            if(e.dirX != 0) {
                e.x := e.x + e.dirX;
            } else {
                e.y := e.y + e.dirY;
            }
            if(checkBlocks(e.x - e.w/2, 
                e.y - e.h/2, 
                e.x + e.w/2, 
                e.y + e.h/2)) {
                e.x := ox;
                e.y := oy;
                e.dirX := e.dirX * -1;
                e.dirY := e.dirY * -1;
            }
            flipX := 0;
            if(e.dirX = 1) {
                flipX := 1;
            }
            drawSprite(e.x, e.y, e.sprite, e.imageIndex, flipX, 0);
        }
        i := i + 1;
     }
}

def checkEnemyCollision(playerSprite) {
    i := 0;
    while(i < len(enemyInstances)) {
        if(checkSpriteCollision(playerSprite, enemyInstances[i].sprite)) {
            return true;
        }
        i := i + 1;
    }
    return false;
}
