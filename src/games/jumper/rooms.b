const BLOCK_KEY = 0;
const KEY_KEY = 1;
const DOOR_KEY = 2;

blockDefs := {
    "x": [ "b1", true, 0, 0, false ],
    ".": [ "b2", false, -3, -5, true ],
    "k": [ "key", false, 0, 0, false ],
    "d": [ "door", true, 0, 0, false ],
    "o": [ "open", false, 0, 0, false ]
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
        "d...........x....k.x",
        "xxxx........x......x",
        "xk..........x......x",
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
doorBlockIndex := 0;

def drawBlocks(isBackground) {
    row := 0; 
    room := rooms[roomIndex];
    while(row < len(room)) {
        x := 0;
        while(x < len(room[row])) {
            c := substr(room[row], x, 1);
            b := blockDefs[c];
            if(isBackground = b[4] && (isBackground = false || random() > 0.85)) {
                if(b[1]) {
                    drawImage(x * BLOCK_WIDTH + b[2], row * BLOCK_HEIGHT + b[3], img[b[0]]);
                    blockIndex := addBoundingBox(
                        BLOCK_KEY, 
                        x * BLOCK_WIDTH, 
                        row * BLOCK_HEIGHT,
                        (x + 1) * BLOCK_WIDTH, 
                        (row + 1) * BLOCK_HEIGHT
                    );
                    if(c = "d") {
                        doorBlockIndex := blockIndex;
                    }
                } else {
                    drawImage(x * BLOCK_WIDTH + b[2], row * BLOCK_HEIGHT + b[3], img[b[0]]);
                    if(c = "k") {
                        addBoundingBox(
                            KEY_KEY, 
                            x * BLOCK_WIDTH, 
                            row * BLOCK_HEIGHT,
                            (x + 1) * BLOCK_WIDTH, 
                            (row + 1) * BLOCK_HEIGHT
                        );
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
    clearBoundingBoxes(BLOCK_KEY);
    clearBoundingBoxes(DOOR_KEY);
    clearBoundingBoxes(KEY_KEY);

    # draw background
    drawBlocks(true);
    # draw foreground
    drawBlocks(false);
}

def checkBlocks(x1, y1, x2, y2) {
    b := checkBoundingBoxes(BLOCK_KEY, x1, y1, x2, y2);
    if(b > -1) {
        return true;
    }
    return false;    
}

def checkKeys(x1, y1, x2, y2) {
    b := checkBoundingBoxes(KEY_KEY, x1, y1, x2, y2);
    if(b > -1) {
        r := getBoundingBox(KEY_KEY, b);
        fillRect(r[0], r[1], r[2], r[3], COLOR_BLACK);
        delBoundingBox(KEY_KEY, b);
        updateVideo();
        return true;
    }
    return false;    
}

def checkDoors(x1, y1, x2, y2) {
    b := checkBoundingBoxes(DOOR_KEY, x1, y1, x2, y2);
    if(b > -1) {
        return true;
    }
    return false;
}

def openGate() {
    r := getBoundingBox(BLOCK_KEY, doorBlockIndex);
    drawImage(r[0], r[1], img[blockDefs["o"][0]]);
    addBoundingBox(DOOR_KEY, r[0], r[1], r[2], r[3]);
    delBoundingBox(BLOCK_KEY, doorBlockIndex);
    updateVideo();
}
