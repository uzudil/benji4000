const SPEED = 0.1;

def main() {
    setVideoMode(0);
    y := 10;
    while(y > -1) {
        x := random() * 40;
        y := random() * 25;
        fg := random() * 16;
        bg := random() * 16;
        ch := 128 + (random() * (512 - 128));
        drawFont(x, y, fg, bg, ch);
        updateVideo();
    }
    
}
