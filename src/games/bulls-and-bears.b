const CHART_START_X = 20;
const CHART_START_Y = 60;
const CHART_END_X = 150;
const CHART_END_Y = 150;
const CHART_INTERVAL = 10;
const POINTMAX = 12;
const START_CASH = 10000;

title := true;
info := false;
gameOn := false;
gameOver := false;

chartspeed := .15;
cash := START_CASH;
stocks := [];
stockTimer := 0;
infoTimer := 0;
gameOnTimer := 0;
starty := CHART_START_Y;
endy := CHART_END_Y;
points := [];

def drawStockChart() {
    startx := CHART_START_X;
    starty := CHART_START_Y;
    endx := CHART_END_X;
    endy := CHART_END_Y;
    drawRect(startx, starty, endx, endy, COLOR_LIGHT_BLUE);
    color := COLOR_GREEN;
    x := startx + 1;
    y := starty + int((endy - starty) / 2);

    tx := CHART_START_X - 5;
    ty := CHART_END_Y - 5;
    ti := 0;
    while (ti < 5) {
        drawLine(tx, ty, startx, ty, COLOR_LIGHT_BLUE);
        ti := ti + 1;
        ty := ty - 20;
    }

    i := 0;
    j := i + 1;
    while(i < len(points) && j < len(points)) {
        x1 := x;
        x2 := x + CHART_INTERVAL;
        y1 := points[i];
        y2 := points[j];
        drawLine(x1, y1, x2, y2, COLOR_RED);
        i := i + 1;
        j := i + 1;
        x := x2;
    }
}

def drawDelayedChart() {
    y := starty + int((endy - starty) / 2);
    if(getTicks() > stockTimer) {
        stockTimer := getTicks() + chartspeed;
        rand := int(random() * 10) + int(random() * 15);
        if (random() > .5) {
            points[len(points)] := y + rand;
        } else {
            points[len(points)] := y - rand;
        }
        while (len(points) >= POINTMAX) {
            del points[0];
        }
    }
    drawStockChart();
}

def drawTitle() {
    drawRect(5, 5, 155, 195, COLOR_DARK_BLUE);
    drawText(20, 20, COLOR_BROWN, COLOR_BLACK, "Bulls and Bears");
    drawText(14, 45, COLOR_MID_GRAY, COLOR_BLACK, "for the Benji4000");
    drawText(25, 160, COLOR_MID_GRAY, COLOR_BLACK, "SPACE to start");
    drawText(14, 175, COLOR_DARK_GRAY, COLOR_BLACK, "2020 (c) by Matt");

    drawDelayedChart();
    if(isKeyDown(KeySpace)) {
        title := false;
        info := true;
        infoTimer := getTicks() + 2;
        while(isKeyDown(KeySpace)) {
        }
    }
}

def drawInfo() {
    drawRect(5, 5, 155, 195, COLOR_DARK_BLUE);
    drawText(14, 25, COLOR_MID_GRAY, COLOR_BLACK, "Can you survive");
    drawText(14, 35, COLOR_MID_GRAY, COLOR_BLACK, "the stock market");
    drawText(14, 45, COLOR_MID_GRAY, COLOR_BLACK, "crash of 2020?");

    drawText(14, 160, COLOR_RED, COLOR_BLACK, "press b to buy");
    drawText(14, 170, COLOR_RED, COLOR_BLACK, "press s to sell");
    drawText(14, 180, COLOR_MID_GRAY, COLOR_BLACK, "SPACE to begin");

    if(getTicks() > infoTimer) {
        points[len(points)] := CHART_END_Y;
        drawStockChart();
        drawExplosion(CHART_END_X - 20, CHART_END_Y);

        if(isKeyDown(KeySpace)) {
            info := false;
            gameOn := true;
            gameOnTimer := getTicks() + 25;
            while(isKeyDown(KeySpace)) {
            }
        }
    } else {
        drawDelayedChart();
    }
}

def drawExplosion(x, y) {
    i := 0;
    while(i < 10) {
        if(random() > 0.75) {
            color := COLOR_YELLOW;
        } else {
            color := COLOR_RED;
        }
        fillCircle(x - 5 + (random() * 10), y - 5 + (random() * 10), random() * 10 + 3, color);
        i := i + 1;
    }
}

def buyStock() {
    cost := points[len(points) - 1];
    if (cost > cash) {
        return false;
    }
    stocks[len(stocks)] := cost;
    cash := cash - cost;
    return true;
}

def sellStock() {
    if (len(stocks) = 0) {
        return false;
    }
    cost := points[len(points) - 1];
    cash := cash + cost;
    del stocks[len(stocks) - 1];
    return true;
}

def calculateValue() {
    i := 0;
    value := 0;
    current := points[len(points) - 1];
    while (i < len(stocks)) {
        cost := stocks[i];
        if (cost > current) {
            value := value - cost;
        }
        if (current > cost) {
            value := value + cost;
        }
        i := i + 1;
    }
    return value;
}

def handleGame() {
    drawText(0, 1, COLOR_LIGHT_BLUE, COLOR_DARK_BLUE, "MONEY:$" + cash);
    drawText(0, 10, COLOR_LIGHT_BLUE, COLOR_DARK_BLUE, "VALUE:$" + calculateValue());
    drawText(0, 20, COLOR_LIGHT_BLUE, COLOR_DARK_BLUE, "STOCKS:" + len(stocks));
    drawText(14, 160, COLOR_LIGHT_BLUE, COLOR_BLACK, "press b to buy");
    drawText(14, 170, COLOR_LIGHT_BLUE, COLOR_BLACK, "press s to sell");

    chartspeed := .5;

    if(getTicks() > gameOnTimer) {
        points[len(points)] := CHART_END_Y;
        drawStockChart();
        drawExplosion(CHART_END_X - 20, CHART_END_Y);
    } else {
        drawDelayedChart();
        if(isKeyDown(KeyB)) {
            buyStock();
            while(isKeyDown(KeyB)) {
            }
        }
        if(isKeyDown(KeyS)) {
            sellStock();
            while(isKeyDown(KeyS)) {
            }
        }
    }
    if(isKeyDown(KeySpace)) {
        gameOn := false;
        gameOver := true;
        while(isKeyDown(KeySpace)) {
        }
    }
}

def main() {
    setVideoMode(2);
    setBackground(COLOR_BLACK);
    
    on := 1;
    while(on=1) {
        clearVideo();
        if(title) {
            drawTitle();
        } else {
            if (info) {
                drawInfo();
            } else {
                if (gameOn) {
                    handleGame();
                } else {
                    if (gameOver) {
                        on := 0;
                    }
                }
            }
        }
        updateVideo();
    }
}
