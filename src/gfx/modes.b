def fillScreen(w, h) {
    index := 0;
    c := 0;
    while(index < w * h) {
        y := index / w;
        x := index % w;
        setPixel(x, y, c);
        c := random() * 16;
        index := index + 1;
    }
    updateVideo();
}

def main() {
    
#    setVideoMode(1);
#    i := 1;
#    while(i < 10) {
#        fillScreen(320, 200);
#    }

    setVideoMode(2);
    i := 1;
    while(i < 10) {
        fillScreen(160, 200);
    }
}
