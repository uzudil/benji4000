blockDefs := {
    "x": [ "b1", true, 0, 0 ],
    ".": [ "b2", false, -4, -8 ],
    "k": [ "key", false, 0, 0 ],
    "d": [ "door", true, 0, 0 ]
};
rooms := [
    [
        "xxxxxxxxxxxxxxxxxxxx",
        "x................k.x",
        "x..................x",
        "x......xxxx........x",
        "xk.................x",
        "xxxx..........xxxxxx",
        "x.................kx",
        "x.........xxx......x",
        "x.................xx",
        "xxxx...............x",
        "xxxx....x..........d",
        "xxxxxxxxxxxxxxxxxxxx"
    ]
];
roomIndex := 0;
blocks := [];
enemies := [];

def drawBlocks(block, eq) {
    row := 0; 
    room := rooms[roomIndex];
    while(row < len(room)) {
        x := 0;
        while(x < len(room[row])) {
            c := substr(room[row], x, 1);
            if((eq = false && c != block) || (eq = true && c = block && random() > 0.85)) {
                b := blockDefs[c];
                if(b[1]) {
                    drawImage(x * BLOCK_WIDTH, row * BLOCK_HEIGHT, img[b[0]]);
                    blocks[len(blocks)] := [
                        x * BLOCK_WIDTH, row * BLOCK_HEIGHT,
                        (x + 1) * BLOCK_WIDTH, (row + 1) * BLOCK_HEIGHT
                    ];
                } else {
                    drawImage(x * BLOCK_WIDTH + b[2], row * BLOCK_HEIGHT + b[3], img[b[0]]);
                }
            }
            x := x + 1;
        }
        row := row + 1;
    }
}

def initEnemies() {
    # todo: make this per room
    setSprite(1, [img["en1"], img["en2"]]);
    setSprite(2, [img["en1"], img["en2"]]);

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

def drawLevel() {
    blocks := [];
    drawBlocks(".", true);
    drawBlocks(".", false);
    initEnemies();
}

# todo: implement in go with quad-tree
def checkBlocks(x1, y1, x2, y2) {
    i := 0;
    while(i < len(blocks)) {
        if(isOverlap(
            x1, y1, x2, y2, 
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
