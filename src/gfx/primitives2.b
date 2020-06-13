r := 10;
dir := 0.5;

def main() {
    setVideoMode(2);
    while(dir != 0) {
        clearVideo();
        drawRect(10, 10, 70, 190, 6);
        fillRect(90, 10, 150, 190, 8);
        drawCircle(80, 100, r + 20, 5);
        fillCircle(80, 100, r + 10, 7);
        r := r + dir;
        if(r >= 70) {
            dir := -1 * dir;
        }
        if(r <= 5) {
            dir := -1 * dir;
        }
        updateVideo();
    }
}
