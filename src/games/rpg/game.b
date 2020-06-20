player := {
    "x": 18,
    "y": 4,
    "map": "bonefell",
    "blockIndex": 0,
};

def initGame() {
    mapName := player.map;
    player.blockIndex := getBlockIndexByName("fighter1");
    loadMap(mapName);
}

def drawUI() {
    clearVideo();
    fillRect(5, 5, 5 + TILE_W * MAP_VIEW_W, 5 + TILE_H * MAP_VIEW_H, COLOR_BLACK);

    # pc-s
    x := 10 + TILE_W * MAP_VIEW_W;
    y := 5;
    fillRect(x, y, x + (320 - x - 5), 40, COLOR_BLACK);

    # messages
    y := 45;
    fillRect(x, y, x + (320 - x - 5), y + ((5 + TILE_H * MAP_VIEW_H) - y), COLOR_BLACK);    
}

def renderGame() {
    drawUI();
    initLight();
    drawView(player.x, player.y);
}

def initLight() {
    mx := player.x - 5; 
    while(mx <= player.x + 5) {
        my := player.y - 5;
        while(my <= player.y + 5) {
            block := getBlock(mx, my);
            if(player.x = mx && player.y = my) {
                block["light"] := 1;
            } else {
                block["light"] := -1;
            }
            my := my + 1;
        }
        mx := mx + 1;
    }
    findLight(player.x, player.y);
}

def findLight(mx, my) {
    dx := mx - player.x;
    dy := my - player.y;
    if(abs(dx) <= 5 && abs(dy) <= 5) {
        block := getBlock(mx, my);
        block.light := 1;
        if(blocks[block.block].blocking = false) {
            if(getBlock(mx - 1, my).light = -1) {
                findLight(mx - 1, my);
            }
            if(getBlock(mx + 1, my).light = -1) {
                findLight(mx + 1, my);
            }
            if(getBlock(mx, my - 1).light = -1) {
                findLight(mx, my - 1);
            }
            if(getBlock(mx, my + 1).light = -1) {
                findLight(mx, my + 1);
            }
            if(getBlock(mx - 1, my - 1).light = -1) {
                findLight(mx - 1, my - 1);
            }
            if(getBlock(mx + 1, my - 1).light = -1) {
                findLight(mx + 1, my - 1);
            }
            if(getBlock(mx - 1, my + 1).light = -1) {
                findLight(mx - 1, my + 1);
            }
            if(getBlock(mx + 1, my + 1).light = -1) {
                findLight(mx + 1, my + 1);
            }

        }
    }
}

def gameIsBlockVisible(mx, my) {
    block := getBlock(mx, my);
    return block["light"] = 1;
}

def gameDrawViewAt(x, y, mx, my) {
    block := getBlock(mx, my);
    if(mx = player.x && my = player.y) {
        drawImage(x, y, img[blocks[player.blockIndex].img], 0);
    }
}

def getMapStartPos(nextMapName) {
    m := links[nextMapName];
    k := keys(m);
    trace("Looking for " + mapName + " in " + m);
    i := 0;
    while(i < len(k)) {
        if(m[k[i]] = mapName) {
            trace("Start player at: " + k[i]);
            pos := split(k[i], ",");
            return [int(pos[0]), int(pos[1])];
        }
        i := i + 1;
    }
    # error
    return null;
}

def gameEnterMap() {
    key := "" + player.x + "," + player.y;
    if(links[mapName] != null) {
        s := links[mapName][key];
        if(s != null) {
            pos := getMapStartPos(s);
            loadMap(s);
            player.x := pos[0];
            player.y := pos[1];
        }
    }
}

def gameUseDoor() {
    dx := -1;
    while(dx <= 1) {
        dy := -1;
        while(dy <= 1) {
            block := blocks[getBlock(player.x + dx, player.y + dy).block];
            if(block["nextState"] != null) {
                setBlock(player.x + dx, player.y + dy, getBlockIndexByName(block.nextState), 0);
                gameMessage("Use door");
                return 0;
            }
            dy := dy + 1;
        }
        dx := dx + 1;
    }
}

def gameMessage(message) {
    trace(message);
}

def gameInput() {
    ox := player.x;
    oy := player.y;
    if(isKeyDown(KeySpace)) {
        while(isKeyDown(KeySpace)) {
        }
        gameEnterMap();
        gameUseDoor();
    }
    if(isKeyDown(KeyUp)) {
        player.y := player.y - 1;
    }
    if(isKeyDown(KeyDown)) {
        player.y := player.y + 1;
    }
    if(isKeyDown(KeyLeft)) {
        player.x := player.x - 1;
    }
    if(isKeyDown(KeyRight)) {
        player.x := player.x + 1;
    }
    block := blocks[getBlock(player.x, player.y).block];
    if(block.blocking) {
        player.x := ox;
        player.y := oy;
    }
}
