def handleInput() {
    if(getTicks() > ticks) {
        if(anyNonHelperKeyDown()) {
            MODES[mode].handleInput();
            ticks := getTicks() + 0.1;
            return true;
        } else {
            ticks := getTicks() + 0.05;
        }
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
            drawImageRot(x * TILE_W + 5, y * TILE_H + 5, mapBlock.rot, mapBlock.xflip, mapBlock.yflip, img[block.img]);
            MODES[mode].drawViewAt(x * TILE_W + 5, y * TILE_H + 5, mx - 5 + x, my - 5 + y);
            y := y + 1;
        }
        x := x + 1;
    }
}

def renderGame() {
    drawUI();
    drawView(player.x, player.y);
}

def main() {
    limitFps(30);
    setVideoMode(1);
    setBackground(COLOR_BLACK);

    img := load("img.dat");
    links := load("links");
    
    setColor(COLOR_TEAL, 24, 120, 24);
    initBlocks();
    MODES[mode].init();
    MODES[mode].render();
    while(true) {
        handleInput();
        MODES[mode].render();
        updateVideo();
    }
}
