const PAINT_MODE = 1;
const HELP_MODE = 2;
const NEW_IMAGE_MODE = 3;
const SAVE_IMAGE_MODE = 4;
const LOAD_IMAGE_MODE = 5;
const CLONE_IMAGE_MODE = 6;
const DELETE_IMAGE_MODE = 7;

mode := PAINT_MODE;
width := 64;
height := 64;
x := width / 2;
y := height / 2;
color := 1;
bcolor := 0;
timer := 0;
img := {};
name := "Drawing";

const FILE_NAME = "img.dat";
composite := {};

# 0-no pen, 1-draw, 2-erase
pendown := 0; 
const PEN = [ "move", "draw", "erase" ];

def drawColors(x, y) {
    c := 0;
    while(c < 8) {
        fillRect(x + c * 10, y, x + (c + 1) * 10, y+10, c);
        fillRect(x + c * 10, y+10, x + (c + 1) * 10, y+20, c + 8);
        c := c + 1;
    }
    drawRect(
        x + (color % 8) * 10, 
        y + int(color / 8) * 10, 
        x+10 + (color % 8) * 10, 
        y+10 + int(color / 8) * 10, 
        COLOR_YELLOW);
    drawRect(
        x + (bcolor % 8) * 10, 
        y + int(bcolor / 8) * 10, 
        x+10 + (bcolor % 8) * 10, 
        y+10 + int(bcolor / 8) * 10, 
        COLOR_WHITE);
}

def paintMode() {
    # draw the ui
    drawRect(1, 1, 2 + width, 2 + height, COLOR_MID_GRAY);
    drawColors(80, 2);
    drawText(2, 100, COLOR_MID_GRAY, COLOR_BLACK, "POS:" + x + "," + y);
    drawText(2, 110, COLOR_MID_GRAY, COLOR_BLACK, "SIZ:" + width + "," + height);
    drawText(2, 120, COLOR_MID_GRAY, COLOR_BLACK, name);
    drawText(2, 130, COLOR_MID_GRAY, COLOR_BLACK, "Pen:" + PEN[pendown]);
    drawText(2, 140, COLOR_MID_GRAY, COLOR_BLACK, "Clone:" + img["clone"]);    

    drawText(80, 30, COLOR_MID_GRAY, COLOR_BLACK, "Help: H");

    # draw our image
    drawImage(2, 2, img);

    handleInput();

    # draw the cursor
    setPixel(x + 2, y + 2, COLOR_YELLOW);
}

def switchTo(imageName) {
    name := imageName;
    img := composite[name];
    width := getImageWidth(img);
    height := getImageHeight(img);
    x := width/2;
    y := height/2;
}

def main() {
    setVideoMode(2);
    setBackground(COLOR_BLACK);    
    clearVideo();

    # try to load the file
    loadedData := load(FILE_NAME);
    if(loadedData = null) {
        img := getImage(2, 2, 2 + width, 2 + height);
        composite[name] := img;
    } else {
        # fixme: writing: keys(composite)[0] is an error?
        composite := loadedData;
        k := keys(composite);
        switchTo(k[0]);
    }

    while(true) {
        clearVideo();
        if(mode = PAINT_MODE) {
            paintMode();
        }
        if(mode = HELP_MODE) {
            helpMode();
        }
        if(mode = NEW_IMAGE_MODE) {
            newImageMode();
        }
        if(mode = SAVE_IMAGE_MODE) {
            saveImageMode();
        }
        if(mode = LOAD_IMAGE_MODE) {
            loadImageMode();
        }
        if(mode = CLONE_IMAGE_MODE) {
            cloneImageMode();
        }
        if(mode = DELETE_IMAGE_MODE) {
            deleteImageMode();
        }
        updateVideo();
    }
}
