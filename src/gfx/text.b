def main() {
    setVideoMode(0);
    x := 0;
    fg := 0;
    bg := 15;
    while(x > -1) {
        drawText(x, x, fg, bg, "Text drawn with BScript!");
        x := x + 1;
        if(x > 25) {
            x := 0;
        }
        fg := fg + 1;
        if(fg > 15) {
            fg := 0;
        }
        bg := bg - 1;
        if(bg < 0) {
            bg := 15;
        }
        updateVideo();
    }    
}
