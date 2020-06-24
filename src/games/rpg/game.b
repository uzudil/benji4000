player := {
    "x": 18,
    "y": 4,
    "map": "bonefell",
    "blockIndex": 0,
    "messages": [],
    "gameState": {},
    "blocks": {},
};

npc := [];

def initGame() {
    # init the maps
    events["almoc"] := events_almoc;
    events["bonefell"] := events_bonefell;
    events["redclaw"] := events_redclaw;
    events["world1"] := events_world1;

    savegame := load("savegame.dat");
    if(savegame = null) {
        gameMessage("You awake underground.", COLOR_YELLOW);
    } else {
        player := savegame;
        gameMessage("You continue on your adventure.", COLOR_WHITE);
    }
    player.blockIndex := getBlockIndexByName("fighter1");
    player["image"] := img[blocks[player.blockIndex].img];
    mapName := player.map;
    gameLoadMap(mapName);
}

def gameLoadMap(name) {
    loadMap(name);    
    applyGameBlocks(name);
    if(events[name]["onNpcInit"] != null) {
        npc := events[name].onNpcInit();
        array_foreach(npc, (i, e) => {
            e["image"] := img[blocks[getBlockIndexByName(e.block)].img];
            e["start"] := [e.pos[0], e.pos[1]];
        });
    }
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
    moveNpcs();
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
        drawImage(x, y, player.image, 0);
    }
    array_foreach(npc, (i, e) => {
        if(e.pos[0] = mx && e.pos[1] = my) {
            drawImage(x, y, e.image, 0);
        }
    });
}

def moveNpcs() {
    array_foreach(npc, (i, e) => {
        if(random() > 0.5) {
            dx := choose([ 1, -1 ]);
            dy := choose([ 1, -1 ]);
            e.pos[0] := e.pos[0] + dx;
            e.pos[1] := e.pos[1] + dy;
            block := blocks[getBlock(e.pos[0], e.pos[1]).block];
            if(block.blocking || 
                abs(e.pos[0] - e.start[0]) > 5 || 
                abs(e.pos[1] - e.start[1]) > 5 || 
                (e.pos[0] = player.x && e.pos[1] = player.y)
            ) {
                e.pos[0] := e.pos[0] - dx;
                e.pos[1] := e.pos[1] - dy;
            }
        }
    });
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

def applyGameBlocks(newMapName) {
    # apply map block changes (doors, secrets, etc)
    m := player.blocks[newMapName];
    if(m != null) {
        k := keys(m);
        i := 0;
        while(i < len(k)) {
            pos := split(k[i], ",");
            setBlock(int(pos[0]), int(pos[1]), m[k[i]], 0);
            i := i + 1;
        }
    }
}

def gameEnterMap() {
    key := "" + player.x + "," + player.y;
    if(links[mapName] != null) {
        s := links[mapName][key];
        if(s != null) {
            pos := getMapStartPos(s);
            gameLoadMap(s);

            player.x := pos[0];
            player.y := pos[1];
            player.map := s;
            saveGame();
            if(events[s] != null) {
                events[s].onEnter();
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
            index := getBlockIndexByName(block.nextState);
            setBlock(x, y, index, 0);
            setGameBlock(x, y, index);
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
            setGameBlock(x, y, space);
            gameMessage("Found a secret door!", COLOR_MID_GRAY);
            return 1;
        } else {
            return null;
        }
    });
}

def setGameState(name, value) {
    player.gameState[name] := value;
    saveGame();
}

def setGameBlock(x, y, index) {
    if(player.blocks[player.map] = null) {
        player.blocks[player.map] := {};
    }
    player.blocks[player.map]["" + x + "," + y] := index;
    saveGame();
}

def saveGame() {
    save("savegame.dat", player);
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
