blockDefs := {
    "x": [ "b1", true ],
    ".": [ "b2", false ]
};
rooms := [
    [
        "xxxxxxxxxxxxxxxxxxxx",
        "x..................x",
        "x..................x",
        "x..................x",
        "x..................x",
        "x.............xxxxxx",
        "x..................x",
        "x......xxxxxx......x",
        "x..................x",
        "xxx................x",
        "x..................x",
        "xxxxxxxxxxxxxxxxxxxx"
    ]
];
roomIndex := 0;
blocks := [];

def drawBlocks(block) {
    row := 0; 
    room := rooms[roomIndex];
    while(row < len(room)) {
        x := 0;
        while(x < len(room[row])) {
            c := substr(room[row], x, 1);
            if(c = block) {
                b := blockDefs[block];
                if(b[1]) {
                    drawImage(x * BLOCK_WIDTH, row * BLOCK_HEIGHT, img[b[0]]);
                    blocks[len(blocks)] := [
                        x * BLOCK_WIDTH, row * BLOCK_HEIGHT,
                        (x + 1) * BLOCK_WIDTH, (row + 1) * BLOCK_HEIGHT
                    ];
                } else {
                    if(random() > 0.85) {
                        drawImage(x * BLOCK_WIDTH - 4, row * BLOCK_HEIGHT - 8, img[b[0]]);
                    }
                }
            }
            x := x + 1;
        }
        row := row + 1;
    }
}

def drawLevel() {
    blocks := [];
    drawBlocks(".");
    drawBlocks("x");
}

# todo: implement in go with quad-tree
def checkBlocks() {
    i := 0;
    while(i < len(blocks)) {
        if(isOverlap(
            player["x"] - PLAYER_WIDTH/2, 
            player["y"] - PLAYER_HEIGHT/2, 
            player["x"] + PLAYER_WIDTH/2, 
            player["y"] + PLAYER_HEIGHT/2, 
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
