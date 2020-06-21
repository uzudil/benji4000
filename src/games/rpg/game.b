player := {
    "x": 18,
    "y": 4,
    "map": "bonefell",
    "blockIndex": 0,
    "messages": [],
};

const MAP_MESSAGES = {
    "almoc": "You arrive in Almoc",
    "redclaw": "The forest fastness of Redclaw",
    "bonefell": "Bonefell dungeon",
};

def initGame() {
    mapName := player.map;
    player.blockIndex := getBlockIndexByName("fighter1");
    loadMap(mapName);
    gameMessage("You awake underground.", COLOR_YELLOW);
}

def drawUI() {
    clearVideo();
    drawRect(4, 5, 5 + TILE_W * MAP_VIEW_W, 5 + TILE_H * MAP_VIEW_H, COLOR_DARK_BLUE);

    # pc-s
    x := 10 + TILE_W * MAP_VIEW_W;
    y := 5;
    drawRect(x, y, x + (320 - x - 5), 40, COLOR_DARK_BLUE);

    # messages
    y := y + ((5 + TILE_H * MAP_VIEW_H) - y) - 100;
    drawRect(x, y, x + (320 - x - 5), y + ((5 + TILE_H * MAP_VIEW_H) - y), COLOR_DARK_BLUE); 

    ty := y + ((5 + TILE_H * MAP_VIEW_H) - y) - 10;
    i := len(player.messages) - 1;
    while(i >= 0) {
         drawText(x + 2, ty + 2, player.messages[i][1], COLOR_BLACK, player.messages[i][0]);
         i := i - 1;
         ty := ty - 10;
    }   
}

def gameMessage(message, color) {
    i := 0;
    while(i < len(message)) {
        start := i;
        stop := i;
        nextSpace := i;
        while(nextSpace < len(message) && nextSpace - start < 16) {
            while(nextSpace < len(message) && substr(message, nextSpace, 1) != " ") {
                nextSpace := nextSpace + 1;
            }
            if(nextSpace - start < 16) {
                stop := nextSpace;
            }
            nextSpace := nextSpace + 1;
        }
        player.messages[len(player.messages)] := [substr(message, start, stop - start), color];
        while(len(player.messages) > 10) {
            del player.messages[0];
        }
        i := stop + 1;
    }
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
    i := 0;
    while(i < len(k)) {
        if(m[k[i]] = mapName) {
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
            
            if(MAP_MESSAGES[s] != null) {
                gameMessage(MAP_MESSAGES[s], COLOR_LIGHT_BLUE);
            } else {
                gameMessage("Enter another area.", COLOR_MID_GRAY);
            }
        }
    }
}

def aroundPlayer(fx) {
    dx := -1;
    while(dx <= 1) {
        dy := -1;
        while(dy <= 1) {
            res := fx(player.x + dx, player.y + dy);
            if(res != null) {
                return res;
            }
            dy := dy + 1;
        }
        dx := dx + 1;
    }
    return null;
}

def gameUseDoor() {
    aroundPlayer((x, y) => {
        block := blocks[getBlock(x, y).block];
        if(block["nextState"] != null) {
            setBlock(x, y, getBlockIndexByName(block.nextState), 0);
            gameMessage("Use a door.", COLOR_MID_GRAY);
            return 1;
        } else {
            return null;
        }
    });
}

def gameSearch() {
    aroundPlayer((x, y) => {
        space := getBlockIndexByName("space");
        block := getBlock(x, y).block;
        if(map.secrets["" + x + "," + y] = 1 && block != space) {
            setBlock(x, y, space, 0);
            gameMessage("Found a secret door!", COLOR_MID_GRAY);
            return 1;
        } else {
            return null;
        }
    });
}

def gameInput() {
    ox := player.x;
    oy := player.y;
    if(isKeyDown(KeySpace)) {
        while(isKeyDown(KeySpace)) {
        }
        gameEnterMap();
        gameUseDoor();
        gameSearch();
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
    if(block.blocking || player.x < 0 || player.y < 0 || player.x >= map.width || player.y >= map.height) {
        player.x := ox;
        player.y := oy;
    }
}
