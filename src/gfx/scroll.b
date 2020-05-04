const SPEED = 0.0075;
const TOP = 1;
const BOTTOM = 2;
const LEFT = 3;
const RIGHT = 4;

def draw(border) {
    c := 0;
    while(c < 10) {
        if(border = BOTTOM) {
            x := random() * 154;
            y := 194;
        }
        if(border = TOP) {
            x := random() * 154;
            y := 5;
        }
        if(border = LEFT) {
            x := 5;
            y := random() * 194;
        }
        if(border = RIGHT) {
            x := 154;
            y := random() * 194;
        }
        fillCircle(x, y, 5, random() * 16);
        c := c + 1;
    }
    updateVideo();
}

def doScrolling(dx, dy) {
    time := getTicks();
    lastTime := getTicks();
    stopTime := time + 2;
    scrollCount := 0;
    while(time < stopTime) {
        if (time - lastTime > SPEED) {
            scroll(dx, dy);
            updateVideo();
            lastTime := time;
            scrollCount := scrollCount + 1;            
        }
        if(scrollCount >= 10) {
            if(dy != 0) {
                if(dy < 0) {
                    draw(BOTTOM);
                } else {
                    draw(TOP);
                }
            }
            if(dx != 0) {
                if(dx < 0) {
                    draw(RIGHT);
                } else {
                    draw(LEFT);
                }
            }
            scrollCount := 0;
        }
        time := getTicks();
    }
}

def main() {
    setVideoMode(2);
    while(1=1) {
        doScrolling(0, -1);
        doScrolling(0, 1);
        doScrolling(-1, 0);
        doScrolling(1, 0);
        doScrolling(1, 1);
        doScrolling(-1, 1);
        doScrolling(-1, -1);
        doScrolling(1, -1);
    }
    trace("Done");
}
