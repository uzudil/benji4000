enemies := [
    {
        "sprite": 1,
        "x": 40,
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
    },
    {
        "sprite": 2,
        "x": 80,
        "y": 165,
        "w": 8,
        "h": 16,
        "timer": 0,
        "dirX": 1,
        "dirY": 0,
        "imageIndex": 0,
        "imageCount": 2,
        "speed": 0.04,
        "animationSteps": 0.2
    }
];

perRoom := [
    [
        [ 40, 40, 0, 1],
        [ 80, 165, 1, 0]
    ],
    [
        [ 80, 40, 0, 1],
        [ 80, 140, 1, 0]
    ]
];

def initEnemies() {
    i := 0;
    while(i < len(enemies)) {
        enemies[i]["x"] := perRoom[roomIndex][i][0];
        enemies[i]["y"] := perRoom[roomIndex][i][1];
        enemies[i]["dirX"] := perRoom[roomIndex][i][2];
        enemies[i]["dirY"] := perRoom[roomIndex][i][3];
        i := i + 1;
    }
}

def moveEnemies() {
     i := 0;
     while(i < len(enemies)) {
        e := enemies[i];
        if(getTicks() > e["timer"]) {
            e["imageIndex"] := e["imageIndex"] + e["animationSteps"];
            if(e["imageIndex"] >= e["imageCount"]) {
                e["imageIndex"] := 0;
            }
            e["timer"] := getTicks() + e["speed"];

            # move
            ox := e["x"];
            oy := e["y"];
            if(e["dirX"] != 0) {
                e["x"] := e["x"] + e["dirX"];
            } else {
                e["y"] := e["y"] + e["dirY"];
            }
            if(checkBlocks(e["x"] - e["w"]/2, 
                e["y"] - e["h"]/2, 
                e["x"] + e["w"]/2, 
                e["y"] + e["h"]/2)) {
                e["x"] := ox;
                e["y"] := oy;
                e["dirX"] := e["dirX"] * -1;
                e["dirY"] := e["dirY"] * -1;
            }
            drawSprite(e["x"], e["y"], e["sprite"], e["imageIndex"], 0, 0);
        }
        i := i + 1;
     }
}
