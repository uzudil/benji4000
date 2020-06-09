ch := 0;
const sample = [
    [ 550, 600, 550, 650, 700, 800 ],
    [ 200, 100, 200, 150 ],
    [ 990, 1100, 1500, 1800, 1200, 1200 ],
];
const paused = [ true, true, true ];

def drawUI() {
    i := 0;
    x := 10;
    while(i < 3) {
        if(i = ch) {
            fillRect(x, 20, x + 30, 40, COLOR_YELLOW);
        } else {
            fillRect(x, 20, x + 30, 40, COLOR_WHITE);
        }
        if(paused[i]) {
            fillRect(x + 10, 25, x + 12, 35, COLOR_LIGHT_BLUE);
            fillRect(x + 20, 25, x + 22, 35, COLOR_LIGHT_BLUE);
        }
        x := x + 40;
        i := i + 1;
    }
    drawText(20, 50, COLOR_WHITE, COLOR_LIGHT_BLUE, "Keys:");
    drawText(20, 70, COLOR_WHITE, COLOR_LIGHT_BLUE, "1,2,3 - switch");
    drawText(20, 90, COLOR_WHITE, COLOR_LIGHT_BLUE, "space - toggle");
    drawText(20, 110, COLOR_WHITE, COLOR_LIGHT_BLUE, "Esc - quit");
    updateVideo();
}

def toggleSample(n) {
    if(paused[n]) {
        paused[n] := false;
    } else {
        paused[n] := true;
    }
    pauseSound(n, paused[n]);
}

def initSamples() {
    n := 0;
    while(n < 3) {
        clearSound(n);
        pauseSound(n, true);
        i := 0;
        while(i < len(sample[n])) {
            playSound(n, sample[n][i], 0.3);
            i := i + 1;
        }
        loopSound(n, true);
        n := n + 1;
    }
}

const inputMap = [
    {
        "keyValue": Key1,
        "action": self => {
            ch := 0;
        },
    },
    {
        "keyValue": Key2,
        "action": self => {
            ch := 1;
        },
    },    
    {
        "keyValue": Key3,
        "action": self => {
            ch := 2;
        },
    },
    {
        "keyValue": KeySpace,
        "action": self => {
            toggleSample(ch);
        },
    },
];

def main() {
    setVideoMode(2);
    initSamples();
    drawUI();

    while(isKeyDown(KeyEscape) = false) {
        i := 0;
        while(i < len(inputMap)) {
            if(isKeyDown(inputMap[i].keyValue)) {
                while(anyKeyDown()) {
                }
                inputMap[i].action();
                drawUI();
            }
            i := i + 1;
        }
    }
}
