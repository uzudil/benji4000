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

const MOVE = 1;
const CONVO = 2;
const TRADE = 3;
const COMBAT = 4;
gameMode := MOVE;

convo := {
    "npc": null,
    "map": null,
    "key": null,
    "answers": [],
};

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
    } else {
        npc := [];
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
    color := COLOR_DARK_BLUE;
    if(gameMode = CONVO) {
        color := COLOR_TEAL;
    }
    drawRect(x, y, x + (320 - x - 5), y + ((5 + TILE_H * MAP_VIEW_H) - y), color); 

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
    if(gameMode = MOVE) {        
        moveNpcs();
    }
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
            ss := split(s, ",");
            if(len(ss) > 1) {
                gameLoadMap(ss[0]);
                player.map := ss[0];
                player.x := int(ss[1]);
                player.y := int(ss[2]);
            } else {
                pos := getMapStartPos(s);
                gameLoadMap(s);
                player.x := pos[0];
                player.y := pos[1];
                player.map := s;
            }            
            saveGame();
            if(events[mapName] != null) {
                events[mapName].onEnter();
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

def gameConvo() {
    aroundPlayer((x, y) => {
        n := array_find(npc, e => e.pos[0] = x && e.pos[1] = y);
        if(n != null && events[mapName]["onConvo"] != null) {
            convo := events[mapName].onConvo(n);
            if(convo != null) {
                startConvo(n, convo);
                return 1;
            }
        }
        return null;
    });
}

def startConvo(theNpc, theConvoMap) {
    gameMode := CONVO;
    convo.npc := theNpc;
    convo.map := theConvoMap;
    convo.key := "";

    gameMessage("Talking to " + theNpc.name, COLOR_GREEN);
    showConvoText();
}

def showConvoText() {
    result := {
        "words": "",
        "answers": [ [ "Bye", "bye" ] ],
    };
    array_foreach(split(convo.map[convo.key], " "), (i, s) => {
        if(len(result.words) > 0) {
            result.words := result.words + " ";
        }
        if(substr(s, 0, 1) = "$") {
            # remove trailing punctuation
            w := split(s, "[.,!?:;]");
            ss := split(substr(w[0], 1), "\\|");
            if(len(ss) > 1) {
                result.answers[len(result.answers)] := [ ss[0], ss[1] ];
            } else {
                result.answers[len(result.answers)] := [ ss[0], ss[0] ];
            }
            result.words := result.words + ss[0];

            # add the punctuation
            result.words := result.words + substr(s, len(w[0]));
        } else {
            result.words := result.words + s;
        }
    });
    gameMessage(result.words, COLOR_MID_GRAY);
    array_foreach(result.answers, (i, s) => gameMessage("" + (i + 1) + ": " + s[0], COLOR_WHITE));
    convo.answers := result.answers;
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
    if(gameMode = MOVE) {
        ox := player.x;
        oy := player.y;
        if(isKeyDown(KeySpace)) {
            while(isKeyDown(KeySpace)) {
            }
            gameEnterMap();
            gameUseDoor();
            gameSearch();
            gameConvo();
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
        } else {
            # if stepping on an npc, swap places
            n := array_find(npc, e => e.pos[0] = player.x && e.pos[1] = player.y);
            if(n != null) {
                n.pos[0] := ox;
                n.pos[1] := oy;
            }    
        }
    }

    if(gameMode = CONVO) {
        index := null;
        if(isKeyDown(Key1) || isKeyDown(KeyEscape)) {
            while(anyKeyDown()) {}
            index := 0;
        }
        if(isKeyDown(Key2)) {
            while(anyKeyDown()) {}
            index := 1;
        }
        if(isKeyDown(Key3)) {
            while(anyKeyDown()) {}
            index := 2;
        }
        if(isKeyDown(Key4)) {
            while(anyKeyDown()) {}
            index := 3;
        }
        if(isKeyDown(Key5)) {
            while(anyKeyDown()) {}
            index := 4;
        }
        if(index != null) {
            if(index = 0) {
                gameMode := MOVE;
                gameMessage("Bye.", COLOR_MID_GRAY);
            } else {
                if(len(convo.answers) > index) {
                    convo.key := convo.answers[index][1];
                    showConvoText();
                }
            }
        }
    }
}
