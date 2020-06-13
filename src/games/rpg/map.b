def loadMap(name) {
    loadedData := load(name);
    if(loadedData = null) {
        map := {
            "blocks": [],
            "width": 96,
            "height": 96,
        };
        x := 0;
        while(x < map.width) {
            map.blocks[x] := [];
            y := 0;
            while(y < map.height) {
                map.blocks[x][y] := { "block": 0, "rot": 0 };
                y := y + 1;
            }
            x := x + 1;
        }
    } else {
        trace("Loaded map " + name);
        map := loadedData;
    }
}

def saveMap(name) {
    save(name, map);
    trace("Saved map " + name);
}

def normalizeMapCoords(mx, my) {
    if(mx < 0) {
        mx := mx + map.width;
    }
    if(mx >= map.width) {
        mx := mx - map.width;
    }
    if(my < 0) {
        my := my + map.height;
    }
    if(my >= map.height) {
        my := my - map.height;
    }
    return { "x": mx, "y": my };
}

def getBlock(mx, my) {
    c := normalizeMapCoords(mx, my);
    return map.blocks[c.x][c.y];
}

def setBlock(mx, my, blockIndex, rot) {
    c := normalizeMapCoords(mx, my);
    if(map.blocks[c.x][c.y] = null) {
        map.blocks[c.x][c.y] := { "block": blockIndex, "rot": rot };
    } else {
        if(map.blocks[c.x][c.y].block != blockIndex || map.blocks[c.x][c.y].rot != rot) {
            map.blocks[c.x][c.y].block := blockIndex;
            map.blocks[c.x][c.y].rot := rot;
        }
    }
}
