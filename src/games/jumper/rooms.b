blockDefs := {
    "x": [ "b1", true, 0, 0 ],
    ".": [ "b2", false, -4, -8 ],
    "k": [ "key", false, 0, 0 ],
    "d": [ "door", true, 0, 0 ],
    "o": [ "open", false, 0, 0 ]
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
    ],
    [
        "xxxxxxxxxxxxxxxxxxxx",
        "d................k.x",
        "xxxx...............x",
        "xk.................x",
        "xxxxxxxx...........x",
        "xxx..............xxx",
        "xxx................x",
        "xxxxxxxxxxxxx......x",
        "xk.............xxxxx",
        "xxxx...............x",
        "x.........xxx......x",
        "xxxxxxxxxxxxxxxxxxxx"
    ]
];
roomIndex := 0;
blocks := [];
keys := [];
doors := [];
doorBlockIndex := [];

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
                    if(c = "d") {
                        doorBlockIndex[len(doorBlockIndex)] := len(blocks);
                    }
                    blocks[len(blocks)] := [
                        x * BLOCK_WIDTH, row * BLOCK_HEIGHT,
                        (x + 1) * BLOCK_WIDTH, (row + 1) * BLOCK_HEIGHT
                    ];
                } else {
                    drawImage(x * BLOCK_WIDTH + b[2], row * BLOCK_HEIGHT + b[3], img[b[0]]);
                    if(c = "k") {
                        keys[len(keys)] := [
                            x * BLOCK_WIDTH, row * BLOCK_HEIGHT,
                            (x + 1) * BLOCK_WIDTH, (row + 1) * BLOCK_HEIGHT
                        ];
                    }
                }
            }
            x := x + 1;
        }
        row := row + 1;
    }
}

def drawLevel() {
    # reset memory
    blocks := [];
    keys := [];
    doors := [];
    doorBlockIndex := [];

    # draw background
    drawBlocks(".", true);
    # draw foreground
    drawBlocks(".", false);
}

# todo: implement in go with quad-tree
def checkBoundingBoxes(x1, y1, x2, y2, blocks) {
    i := 0;
    while(i < len(blocks)) {
        if(isOverlap(
            x1, y1, x2, y2, 
            blocks[i][0],
            blocks[i][1],
            blocks[i][2],
            blocks[i][3])
        ) {
            return i;
        }
        i := i + 1;
    }
    return -1;
}

def checkBlocks(x1, y1, x2, y2) {
    b := checkBoundingBoxes(x1, y1, x2, y2, blocks);
    if(b > -1) {
        return true;
    }
    return false;    
}

def checkKeys(x1, y1, x2, y2) {
    b := checkBoundingBoxes(x1, y1, x2, y2, keys);
    if(b > -1) {
        fillRect(keys[b][0], keys[b][1], keys[b][2], keys[b][3], COLOR_BLACK);
        del keys[b];
        updateVideo();
        return true;
    }
    return false;    
}

def checkDoors(x1, y1, x2, y2) {
    b := checkBoundingBoxes(x1, y1, x2, y2, doors);
    if(b > -1) {
        return true;
    }
    return false;
}

def openGate() {
    row := 0; 
    room := rooms[roomIndex];
    while(row < len(room)) {
        x := 0;
        while(x < len(room[row])) {
            c := substr(room[row], x, 1);
            if(c = "d") {
                b := blockDefs["o"];
                drawImage(x * BLOCK_WIDTH, row * BLOCK_HEIGHT, img[b[0]]);
                doors[len(doors)] := [
                    x * BLOCK_WIDTH, row * BLOCK_HEIGHT,
                    (x + 1) * BLOCK_WIDTH, (row + 1) * BLOCK_HEIGHT
                ];                
            }
            x := x + 1;
        }
        row := row + 1;
    }

    i := 0;
    while(i < len(doorBlockIndex)) {
        del blocks[doorBlockIndex[i]];
        i := i + 1;
    }
    updateVideo();
    return 1;
}
