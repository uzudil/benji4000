editor := {
    "blockIndex": 0,
    "x": 50,
    "y": 50,
    "showMap": true,
};

def initEditor() {
#    mapName := "bonefell";
    loadMap(mapName);
    if(map = null) {
        newMap(mapName, 96, 96);
    }    
}

def editorEnterMap() {
    key := "" + editor.x + "," + editor.y;
    if(links[mapName] != null) {
        s := links[mapName][key];
        if(s != null) {
            ss := split(s, ",");
            if(len(ss) > 1) {
                loadMap(ss[0]);
                editor.x := int(ss[1]);
                editor.y := int(ss[2]);
            } else {
                loadMap(s);
                editor.x := int(map.width/2);
                editor.y := int(map.height/2);
            }
        }
    }
}

def addSecretDoor() {
    map.secrets["" + editor.x + "," + editor.y] := 1;
}

def addNpc() {
    if(map["npc"] = null) {
        map["npc"] := [];
    }
    setVideoMode(0);
    name := input("NPC name:");
    map.npc[len(map.npc)] := { "name": name, "block": editor.blockIndex, "pos": [ editor.x, editor.y ] };
    saveMap();
    setVideoMode(1);
}

def addMonster() {
    if(map["monster"] = null) {
        map["monster"] := [];
    }
    map.monster[len(map.monster)] := { "block": editor.blockIndex, "pos": [ editor.x, editor.y ] };
    saveMap();
}

def addLink() {
    if(links[mapName] = null) {
        links[mapName] := {};
    }
    setVideoMode(0);
    name := input("New map name:");
    pos := input("New pos (x,y):");
    key := "" + editor.x + "," + editor.y;
    links[mapName][key] := name + "," + pos;
    save("links", links);
    saveMap();
    loadMap(name);
    if(map = null) {
        w := int(input("Width:"));
        h := int(input("Height:"));
        setVideoMode(1);
        newMap(name, w, h);
        saveMap();
    } else {
        setVideoMode(1);
    }
    editor.x := int(map.width/2);
    editor.y := int(map.height/2);
}

def delLink() {
    key := "" + editor.x + "," + editor.y;
    if(links[mapName] != null) {
        s := links[mapName][key];
        if(s != null) {
            if(links[s] != null) {
                del links[s];
            }
            del links[mapName][key];
            saveMap();
            save("links", links);
        }
    }
    if(map.secrets[key] != null) {
        del map.secrets[key];
    }
    npcIndex := array_find_index(map.npc, e => e.pos[0] = editor.x && e.pos[1] = editor.y);
    if(npcIndex > -1) {
        del map.npc[npcIndex];
    }
    monsterIndex := array_find_index(map.monster, e => e.pos[0] = editor.x && e.pos[1] = editor.y);
    if(monsterIndex > -1) {
        del map.monster[monsterIndex];
    }
}

def renderEditor() {
    editorUI();
    drawView(editor.x, editor.y);
}

def editorUI() {
    clearVideo();
    x := 10 + TILE_W * MAP_VIEW_W;
    y := 5;
    fillRect(x, y, x + (320 - x - 5), y + ((5 + TILE_H * MAP_VIEW_H) - y), COLOR_BLACK);    

    blockPalette(x, y);

    drawText(x + 5, 80, COLOR_WHITE, COLOR_BLACK, "Map:" + mapName);
    drawText(x + 5, 90, COLOR_WHITE, COLOR_BLACK, "Pos:" + editor.x + "," + editor.y);
    drawText(5, 190, COLOR_MID_GRAY, COLOR_BLACK, "Press H for help");

    # the map
    if(editor.showMap) {
        drawMap(x + 5, 100);
    }
}

def drawMap(x, y) {
    xp := 0;
    while(xp < map.width) {
        yp := 0;
        while(yp < map.height) {
            if(xp = editor.x && yp = editor.y) {
                setPixel(x + xp, y + yp, COLOR_YELLOW);
            } else {
                setPixel(x + xp, y + yp, minimap[xp][yp]);
            }
            yp := yp + 1;
        }
        xp := xp + 1;
    }
    drawRect(x - 1, y - 1, x - 1 + map.width, y - 1 + map.height, COLOR_MID_GRAY);
    drawRect(x + editor.x - 5, y + editor.y - 5, x + editor.x + 5, y + editor.y + 5, COLOR_YELLOW);
}

def blockPalette(x, y) {
    start := int(editor.blockIndex / 32) * 32;
    i := start;
    xp := x + 5;
    yp := y + 5;
    while(i < len(blocks) && i - start < 32) {
        drawImage(xp, yp, img[blocks[i].img]);
        if(i = editor.blockIndex) {
            drawRect(xp, yp, xp + TILE_W - 1, yp + TILE_H - 1, COLOR_YELLOW);
        }
        i := i + 1;
        xp := xp + TILE_W;
        if(i % 8 = 0) {
            xp := x + 5;
            yp := yp + TILE_H;
        }
    }
}

def editorDrawViewAt(x, y, mx, my) {
    if(mx = editor.x && my = editor.y) {
        drawRect(x, y, x + TILE_W - 1, y + TILE_H - 1, COLOR_YELLOW);
    }
    key := "" + mx + "," + my;
    if(links[mapName] != null) {        
        if(links[mapName][key] != null) {
            drawRect(x + 1, y + 1, x + TILE_W - 2, y + TILE_H - 2, COLOR_RED);
        }
    }
    if(map.secrets[key] = 1) {
        drawRect(x + 1, y + 1, x + TILE_W - 2, y + TILE_H - 2, COLOR_LIGHT_BLUE);
    }
    array_foreach(map.npc, (i, e) => {
        if(e.pos[0] = mx && e.pos[1] = my) {
            drawImage(x, y, img[blocks[e.block].img], 0);
        }
    });
    array_foreach(map.monster, (i, e) => {
        if(e.pos[0] = mx && e.pos[1] = my) {
            drawImage(x, y, img[blocks[e.block].img], 0);
        }
    });
}

def handleEditorInput() {
    if(isKeyDown(KeyEnter)) {
        while(isKeyDown(KeyEnter)) {
        }
        editorEnterMap();
    }
    if(isKeyDown(KeyA)) {
        while(isKeyDown(KeyA)) {
        }
        addLink();
    }
    if(isKeyDown(KeyC)) {
        while(isKeyDown(KeyC)) {
        }
        addSecretDoor();
    }
    if(isKeyDown(KeyD)) {
        while(isKeyDown(KeyD)) {
        }
        delLink();
    }
    if(isKeyDown(KeyN)) {
        while(isKeyDown(KeyN)) {
        }
        addNpc();
    }
    if(isKeyDown(KeyZ)) {
        while(isKeyDown(KeyZ)) {
        }
        addMonster();
    }
    if(isKeyDown(KeyM)) {
        while(isKeyDown(KeyM)) {
        }
        if(editor.showMap) {
            editor.showMap := false;
        } else {
            editor.showMap := true;
        }
    }    
    if(isKeyDown(KeyUp)) {
        editor.y := editor.y - 1;
        if(editor.y < 0) {
            editor.y := editor.y + map.height;
        }
    }
    if(isKeyDown(KeyDown)) {
        editor.y := editor.y + 1;
        if(editor.y >= map.height) {
            editor.y := editor.y - map.height;
        }
    }
    if(isKeyDown(KeyLeft)) {
        editor.x := editor.x - 1;
        if(editor.x < 0) {
            editor.x := editor.x + map.width;
        }
    }
    if(isKeyDown(KeyRight)) {
        editor.x := editor.x + 1;
        if(editor.x >= map.width) {
            editor.x := editor.x - map.width;
        }
    }
    if(isKeyDown(KeySpace) || isKeyDown(KeyLeftShift) || isKeyDown(KeyRightShift)) {
        setBlock(editor.x, editor.y, randomBlockOfType(blocks[editor.blockIndex].type).index, 0);
        if(editor.blockIndex = GRASS) {
            setTransitions(editor.x, editor.y);
        }
        connectRoad(editor.x, editor.y, true);
        connectMine(editor.x, editor.y);
    }
    if(isKeyDown(KeyLeftBracket)) {
        editor.blockIndex := editor.blockIndex - 1;
        if(editor.blockIndex < 0) {
            editor.blockIndex := len(blocks) - 1;
        }
    }
    if(isKeyDown(KeyRightBracket)) {
        editor.blockIndex := editor.blockIndex + 1;
        if(editor.blockIndex >= len(blocks)) {
            editor.blockIndex := 0;
        }
    }
    if(isKeyDown(KeyS)) {
        saveMap();
    }
    if(isKeyDown(KeyF)) {
        fillMap(editor.x, editor.y, getBlock(editor.x, editor.y).block);
    }
    if(isKeyDown(KeyR)) {
        b := getBlock(editor.x, editor.y);
        r := b.rot + 1;
        if(r >= 4) {
            r := 0;
        }
        setBlock(editor.x, editor.y, b.block, r);
    }
    if(isKeyDown(KeyX)) {
        b := getBlock(editor.x, editor.y);
        if(b.xflip = 0) {
            b.xflip := 1;
        } else {
            b.xflip := 0;
        }
    }
    if(isKeyDown(KeyH)) {
        setVideoMode(0);
        print("Keys:");
        print("arrows - move");
        print("shift + arrows, Space - draw");
        print("R - rotate tile");
        print("X - flip tile X");
        print("Y - flip tile Y");
        print("S - Save map");
        print("A - Add link");
        print("C - Add secret door");
        print("D - Delete link/secret door/npc/etc");
        print("Enter - Load linked map");
        print("[,] - change tile");
        print("M - toggle map");
        print("N - add NPC");
        print("Z - add monster");
        print("Press any key");
        while(anyKeyDown() = false) {
        }
        setVideoMode(1);
    }
    if(isKeyDown(KeyY)) {
        b := getBlock(editor.x, editor.y);
        if(b.yflip = 0) {
            b.yflip := 1;
        } else {
            b.yflip := 0;
        }
    }
}

def fillMap(x, y, blockIndex) {
    #trace("fill: pos=" + x + "," + y + " blockIndex=" + blockIndex + " vs " + getBlock(x, y).block);
    if(getBlock(x, y).block = blockIndex) {
        setBlock(x, y, editor.blockIndex, 0);
        if(x - 1 >= 0) {
            if(getBlock(x - 1, y).block = blockIndex) {
                fillMap(x - 1, y, blockIndex);
            }
        }
        if(x + 1 < map.width) {
            if(getBlock(x + 1, y).block = blockIndex) {
                fillMap(x + 1, y, blockIndex);
            }
        }
        if(y - 1 >= 0) {
            if(getBlock(x, y - 1).block = blockIndex) {
                fillMap(x, y - 1, blockIndex);
            }
        }
        if(y + 1 < map.height) {
            if(getBlock(x, y + 1).block = blockIndex) {
                fillMap(x, y + 1, blockIndex);
            }
        }
    }
}

def isMineWall(mx, my) {
    if(mx < 0 || my < 0 || mx >= map.width || my >= map.height) {
        return false;
    }
    s := blocks[getBlock(mx, my).block].img;
    return s = "earth1" || s = "earth2" || s = "earth3";
}

def isMineFloor(mx, my) {
    if(mx < 0 || my < 0 || mx >= map.width || my >= map.height) {
        return false;
    }
    return blocks[getBlock(mx, my).block].img = "earthfloor";
}

def connectMine(mx, my) {
    if(isMineFloor(mx, my)) {
        dx := -1;
        while(dx <= 1) {
            dy := -1;
            while(dy <= 1) {
                if(dx != 0 || dy != 0) {
                    connectMineWall(mx + dx, my + dy);
                }
                dy := dy + 1;
            }
            dx := dx + 1;
        }
    }
}

def connectMineWall(mx, my) {
    if(isMineWall(mx, my)) {
        n := isMineFloor(mx, my - 1);
        s := isMineFloor(mx, my + 1);
        e := isMineFloor(mx + 1, my);
        w := isMineFloor(mx - 1, my);
        if((n && s && e) || (n && s && w) || (e && w && n) || (e && w && s)) {
            setBlock(mx, my, getBlockIndexByName("earthfloor"), 0);
            connectMine(mx, my);
            return 0;
        }
        if(n && e) {
            setBlock(mx, my, getBlockIndexByName("earth3"), 0);
            return 0;
        }
        if(s && e) {
            setBlock(mx, my, getBlockIndexByName("earth3"), 1);
            return 0;
        }
        if(s && w) {
            setBlock(mx, my, getBlockIndexByName("earth3"), 2);
            return 0;
        }
        if(n && w) {
            setBlock(mx, my, getBlockIndexByName("earth3"), 3);
            return 0;
        }
        if(n) {
            setBlock(mx, my, getBlockIndexByName("earth2"), 0);
            return 0;
        }
        if(e) {
            setBlock(mx, my, getBlockIndexByName("earth2"), 1);
            return 0;
        }
        if(s) {
            setBlock(mx, my, getBlockIndexByName("earth2"), 2);
            return 0;
        }
        if(w) {
            setBlock(mx, my, getBlockIndexByName("earth2"), 3);
            return 0;
        }
    }
}

def isRoad(mx, my) {
    return substr(blocks[getBlock(mx, my).block].img, 0, 4) = "road";
}

def connectRoad(mx, my, recurse) {
    if(isRoad(mx, my)) {
        n := isRoad(mx, my - 1);
        s := isRoad(mx, my + 1);
        e := isRoad(mx + 1, my);
        w := isRoad(mx - 1, my);
        if(recurse) {
            if(n) {
                connectRoad(mx, my - 1, false);
            }
            if(s) {
                connectRoad(mx, my + 1, false);
            }
            if(e) {
                connectRoad(mx + 1, my, false);
            }
            if(w) {
                connectRoad(mx - 1, my, false);
            }
        }
        if(n && s && e && w) {
            setBlock(mx, my, getBlockIndexByName("road4"), 0);
            return 0;
        }
        if(n && s && e) {
            setBlock(mx, my, getBlockIndexByName("road3"), 0);
            return 0;
        }
        if(w && s && e) {
            setBlock(mx, my, getBlockIndexByName("road3"), 1);
            return 0;
        }
        if(n && s && w) {
            setBlock(mx, my, getBlockIndexByName("road3"), 2);
            return 0;
        }
        if(n && e && w) {
            setBlock(mx, my, getBlockIndexByName("road3"), 3);
            return 0;
        }
        if(s && e) {
            setBlock(mx, my, getBlockIndexByName("road2"), 0);
            return 0;
        }
        if(s && w) {
            setBlock(mx, my, getBlockIndexByName("road2"), 1);
            return 0;
        }
        if(n && w) {
            setBlock(mx, my, getBlockIndexByName("road2"), 2);
            return 0;
        }
        if(n && e) {
            setBlock(mx, my, getBlockIndexByName("road2"), 3);
            return 0;
        }
        if(n && s) {
            setBlock(mx, my, getBlockIndexByName("road5"), 0);
            return 0;
        }
        if(e && w) {
            setBlock(mx, my, getBlockIndexByName("road5"), 1);
            return 0;
        }
        if(s) {
            setBlock(mx, my, getBlockIndexByName("road1"), 0);
            return 0;
        }
        if(w) {
            setBlock(mx, my, getBlockIndexByName("road1"), 1);
            return 0;
        }
        if(n) {
            setBlock(mx, my, getBlockIndexByName("road1"), 2);
            return 0;
        }
        if(e) {
            setBlock(mx, my, getBlockIndexByName("road1"), 3);
            return 0;
        }
    }
}

def setTransitions(mx, my) {
    dx := -1;
    while(dx <= 1) {
        dy := -1;
        while(dy <= 1) {
            if(dx != 0 || dy != 0) {
                if(blocks[getBlock(mx + dx, my + dy).block].isEdge) {
                    setBlock(mx + dx, my + dy, WATER, 0);
                }
                fixWaterEdge(mx + dx, my + dy);
            }
            dy := dy + 1;            
        }
        dx := dx + 1;
    }
}

def fixWaterEdge(mx, my) {
    if(getBlock(mx, my).block = WATER) {
        w := getBlock(mx - 1, my).block = GRASS;
        e := getBlock(mx + 1, my).block = GRASS;
        n := getBlock(mx, my - 1).block = GRASS;
        s := getBlock(mx, my + 1).block = GRASS;
        nw := getBlock(mx - 1, my - 1).block = GRASS;
        ne := getBlock(mx + 1, my - 1).block = GRASS;
        sw := getBlock(mx - 1, my + 1).block = GRASS;
        se := getBlock(mx + 1, my + 1).block = GRASS;
        
        # single water channel not supported atm
        if((n && s) || (e && w) || (nw && se) || (ne && sw)) {
            setBlock(mx, my, GRASS, 0);
            setTransitions(mx, my);
            return 0;
        }

        # turns
        if(e && n) {
            setBlock(mx, my, TURN, 2);
            return 0;
        }
        if(w && n) {
            setBlock(mx, my, TURN, 1);
            return 0;
        }
        if(e && s) {
            setBlock(mx, my, TURN, 3);
            return 0;
        }
        if(w && s) {
            setBlock(mx, my, TURN, 0);
            return 0;
        }

        # edges
        if(w) {
            setBlock(mx, my, EDGE, 1);
            return 0;
        }
        if(s) {
            setBlock(mx, my, EDGE, 0);
            return 0;
        }
        if(e) {
            setBlock(mx, my, EDGE, 3);
            return 0;
        }
        if(n) {
            setBlock(mx, my, EDGE, 2);
            return 0;
        }

        # corners
        if(ne) {
            setBlock(mx, my, CORNER, 2);
            return 0;
        }
        if(se) {
            setBlock(mx, my, CORNER, 3);
            return 0;
        }
        if(sw) {
            setBlock(mx, my, CORNER, 0);
            return 0;
        }
        if(nw) {
            setBlock(mx, my, CORNER, 1);
            return 0;
        }
    }
}
