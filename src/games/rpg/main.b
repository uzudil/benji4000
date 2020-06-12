def handleInput() {
    if(anyNonHelperKeyDown()) {
        if(getTicks() > ticks) {
            MODES[mode].handleInput();
            ticks := getTicks() + 0.2;
            return true;
        }
    } else {
        ticks := 0;
    }
    return false;    
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

def drawView(mx, my) {
    x := 0; 
    while(x < MAP_VIEW_W) {
        y := 0;
        while(y < MAP_VIEW_H) {
            mapBlock := getBlock(mx - 5 + x, my - 5 + y);
            block := blocks[mapBlock.block];
            if(block.isEdge) {
                #drawImageRot(x * TILE_W + 5, y * TILE_H + 5, 0, img[blocks[WATER].img]);
            }
            drawImageRot(x * TILE_W + 5, y * TILE_H + 5, mapBlock.rot, img[block.img]);
            if(x = 5 && y = 5) {
                MODES[mode].renderMapCursor(x * TILE_W + 5, y * TILE_H + 5);
            }
            y := y + 1;
        }
        x := x + 1;
    }
}

def renderGame() {
    drawUI();
    drawView(player.x, player.y);
    updateVideo();    
}

def main() {
    #setFps(15);
    setVideoMode(1);
    setBackground(COLOR_BLACK);

    img := load("img.dat");
    
    MODES[mode].init();
    MODES[mode].render();
    while(true) {
        if(handleInput()) {
            MODES[mode].render();
        }
    }
}
