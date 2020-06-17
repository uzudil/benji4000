editor := {
    "blockIndex": 0,
    "x": 50,
    "y": 50,
};

def initEditor() {
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
            loadMap(s);
            editor.x := int(map.width/2);
            editor.y := int(map.height/2);
        }
    }
}

def addLink() {
    if(links[mapName] = null) {
        links[mapName] := {};
    }
    setVideoMode(0);
    name := input("New map name:");
    key := "" + editor.x + "," + editor.y;
    links[mapName][key] := name;
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
}

def renderEditor() {
    editorUI();
    drawView(editor.x, editor.y);
    updateVideo();    
}

def editorUI() {
    clearVideo();
    x := 10 + TILE_W * MAP_VIEW_W;
    y := 5;
    fillRect(x, y, x + (320 - x - 5), y + ((5 + TILE_H * MAP_VIEW_H) - y), COLOR_BLACK);    

    blockPalette(x, y);

    drawText(x + 5, 80, COLOR_WHITE, COLOR_BLACK, "Map:" + mapName);
    drawText(x + 5, 90, COLOR_WHITE, COLOR_BLACK, "Pos:" + editor.x + "," + editor.y);

    # the map
    drawMap(x + 5, 100);
}

def drawMap(x, y) {
    xp := 0;
    while(xp < map.width) {
        yp := 0;
        while(yp < map.height) {
            if(xp = editor.x && yp = editor.y) {
                setPixel(x + xp, y + yp, COLOR_YELLOW);
            } else {
                setPixel(x + xp, y + yp, blocks[getBlock(xp, yp).block].color);
            }
            yp := yp + 1;
        }
        xp := xp + 1;
    }
    drawRect(x - 1, y - 1, x - 1 + map.width, y - 1 + map.height, COLOR_MID_GRAY);
    drawRect(x + editor.x - 5, y + editor.y - 5, x + editor.x + 5, y + editor.y + 5, COLOR_YELLOW);
}

def blockPalette(x, y) {
    i := 0;
    xp := x + 5;
    yp := y + 5;
    while(i < len(blocks)) {
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
    if(links[mapName] != null) {
        key := "" + mx + "," + my;
        if(links[mapName][key] != null) {
            drawRect(x + 1, y + 1, x + TILE_W - 2, y + TILE_H - 2, COLOR_RED);
        }
    }
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
    if(isKeyDown(KeyD)) {
        while(isKeyDown(KeyD)) {
        }
        delLink();
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
}

def fillMap(x, y, blockIndex) {
    #trace("fill: pos=" + x + "," + y + " blockIndex=" + blockIndex + " vs " + getBlock(x, y).block);
    if(getBlock(x, y).block = blockIndex) {
        setBlock(x, y, editor.blockIndex, 0);
        if(getBlock(x - 1, y).block = blockIndex) {
            fillMap(x - 1, y, blockIndex);
        }
        if(getBlock(x + 1, y).block = blockIndex) {
            fillMap(x + 1, y, blockIndex);
        }        
        if(getBlock(x, y - 1).block = blockIndex) {
            fillMap(x, y - 1, blockIndex);
        }
        if(getBlock(x, y + 1).block = blockIndex) {
            fillMap(x, y + 1, blockIndex);
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
