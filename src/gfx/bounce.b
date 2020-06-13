# constants
const ne = 1;
const se = 2;
const nw = 3;
const sw = 4;

# global vars
x := [ 80, 10, 130, 40 ];
y := [ 40, 100, 70, 160 ];
dir := [ sw, se, ne, nw ];
speed := [ 0.9, 0.7, 1, 0.5 ];
color := [ 2, 3, 4, 5 ];

def step(index) {
    if(dir[index] = se) {
        x[index] := x[index] + speed[index];
        y[index] := y[index] + speed[index];
    }
    if(dir[index] = ne) {
        x[index] := x[index] + speed[index];
        y[index] := y[index] - speed[index];
    }
    if(dir[index] = sw) {
        x[index] := x[index] - speed[index];
        y[index] := y[index] + speed[index];
    }
    if(dir[index] = nw) {
        x[index] := x[index] - speed[index];
        y[index] := y[index] - speed[index];
    }
}

def boundsCheck(index) {
    if(x[index] >= 150) {
        if(dir[index] = se) {
            dir[index] := sw;            
        }
        if(dir[index] = ne) {
            dir[index] := nw;
        }
    }
    if(x[index] <= 10) {
        if(dir[index] = nw) {
            dir[index] := ne;
        }
        if(dir[index] = sw) {
            dir[index] := se;
        }
    }
    if(y[index] >= 190) {
        if(dir[index] = se) {
            dir[index] := ne;
        }
        if(dir[index] = sw) {
            dir[index] := nw;
        }
    }
    if(y[index] <= 10) {
        if(dir[index] = ne) {
            dir[index] := se;
        }
        if(dir[index] = nw) {
            dir[index] := sw;
        }
    }
}

def drawBorder() {
    drawLine(10, 10, 150, 10, 8);
    drawLine(10, 10, 10, 190, 8);
    drawLine(10, 190, 150, 190, 9);
    drawLine(150, 10, 150, 190, 9);
    drawLine(10, 10, 150, 190, 11);
    drawLine(10, 190, 150, 10, 11);
}

def drawBalls() {
    i := 0;
    while(i < len(dir)) {
        fillCircle(x[i], y[i], 10, color[i]);
        step(i);
        boundsCheck(i);
        i := i + 1;
    }
}

def main() {
    setVideoMode(2);
    while(dir[0] != 0) {
        clearVideo();        
        drawBorder();
        drawBalls();
        updateVideo();
    }
}
