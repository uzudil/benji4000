
const SPEED = 0.01;

def main() {
    setVideoMode(1);
    x := 10;
    y := 10;
    dir := 1;
    while(1=1) {
        clearVideo();
        drawText(x, y, COLOR_BLACK, COLOR_LIGHT_BLUE, "Hello World");
        updateVideo();
        x := x + dir * SPEED;
        y := y + dir * SPEED;
        if(y > 180) {
            dir := -1;
        }
        if(y < 10) {
            dir := 1;
        }
    }
}
