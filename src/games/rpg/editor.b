editor := {
    "map": "world1",
    "blockIndex": 0,
    "x": 50,
    "y": 50,
};

def initEditor() {
    loadMap(editor.map);
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

    drawText(x + 5, 80, COLOR_WHITE, COLOR_BLACK, "Map:" + editor.map);
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
        if(i % 5 = 0) {
            xp := x + 5;
            yp := yp + TILE_H;
        }
    }
}

def renderEditorMapCursor(x, y) {
    drawRect(x, y, x + TILE_W - 1, y + TILE_H - 1, COLOR_YELLOW);
}

def handleEditorInput() {
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
        setBlock(editor.x, editor.y, editor.blockIndex, 0);
        if(editor.blockIndex = GRASS) {
            setTransitions(editor.x, editor.y);
        }
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
        saveMap(editor.map);
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
                applyTransition(mx + dx, my + dy);
            }
            dy := dy + 1;            
        }
        dx := dx + 1;
    }
}

def applyTransition(mx, my) {
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
