const STEPS = 160 / 3;

def main() {
    setVideoMode(2);
    x := 0;
    y := 0;
    while(x <= 160) {
        drawLine(0, 0, x, 200, 14);
        drawLine(0, 0, 160, y, 15);
        x := x + 160 / STEPS;
        y := y + 200 / STEPS;
    }
    c := 0;
    while(c < 8) {
        fillRect(c * 10, 0, c * 10 + 10, 10, c * 2);
        fillRect(c * 10, 10, c * 10 + 10, 20, c * 2 + 1);
        c := c + 1;
    }
    updateVideo();
}
