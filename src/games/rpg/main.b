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
    drawViewRadius(mx, my, 11);
}

def drawViewRadius(mx, my, r) {
    ox := int((MAP_VIEW_W - r)/2);
    oy := int((MAP_VIEW_H - r)/2);
    x := 0; 
    while(x < r) {
        y := 0; 
        while(y < r) {
            px := (x + ox) * TILE_W + 5;
            py := (y + oy) * TILE_H + 5;
            mapx := mx - int(r/2) + x;
            mapy := my - int(r/2) + y;
            if(MODES[mode].isBlockVisible(mapx, mapy)) {
                onScreen := x + ox >= 0 && x + ox < MAP_VIEW_W && y + oy >= 0 && y + oy < MAP_VIEW_H;
                if(onScreen) {
                    mapBlock := getBlock(mapx, mapy);
                    block := blocks[mapBlock.block];
                    drawImageRot(px, py, mapBlock.rot, mapBlock.xflip, mapBlock.yflip, img[block.img]);
                }
                MODES[mode].drawViewAt(px, py, mapx, mapy, onScreen);
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
