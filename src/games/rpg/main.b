def handleInput() {
    if(getTicks() > ticks) {
        if(anyNonHelperKeyDown()) {
            MODES[mode].handleInput();
            ticks := getTicks() + 0.15;
            return true;
        } else {
            ticks := getTicks() + 0.05;
        }
    }
    return false;    
}

def drawView(mx, my) {
    x := 0; 
    while(x < MAP_VIEW_W) {
        y := 0;
        while(y < MAP_VIEW_H) {
            if(MODES[mode].isBlockVisible(mx - 5 + x, my - 5 + y)) {
                mapBlock := getBlock(mx - 5 + x, my - 5 + y);
                block := blocks[mapBlock.block];
                drawImageRot(x * TILE_W + 5, y * TILE_H + 5, mapBlock.rot, mapBlock.xflip, mapBlock.yflip, img[block.img]);
                MODES[mode].drawViewAt(x * TILE_W + 5, y * TILE_H + 5, mx - 5 + x, my - 5 + y);
            }
            y := y + 1;
        }
        x := x + 1;
    }
}

def main() {
    #limitFps(30);
    setVideoMode(1);
    setBackground(COLOR_BLACK);

    img := load("img.dat");
    links := load("links");
    
    setColor(COLOR_TEAL, 24, 120, 24);
    initBlocks();
    MODES[mode].init();
    MODES[mode].render();
    updateVideo();
    while(true) {
        if(handleInput()) {
            MODES[mode].render();
        }
        updateVideo();
    }
}
