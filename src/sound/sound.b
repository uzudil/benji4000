const freqC = 523.3;
const freqE = 659.3;
const freqG = 784.0;

def playSounds() {
    i := 0;
    while(i < 100) {
        if(i % 2 = 0) {
            playSound(0, 120, 0.5);
        } else {
            playSound(0, 150, 0.5);
        }
        i := i + 1;
    }
    playSound(1, 0, 2);
    f := 400;
    while(f < 1000) {
        playSound(1, f, 0.1);
        f := f + 10;
    }   
}

def main() {
    playSounds();
    setVideoMode(1); 
    while(anyKeyDown() = false) {
        x := random() * 320;
        y := random() * 200;
        r := random() * 30;
        c := random() * 16;
        fillRect(x, y, x + r, y + r, c);
        updateVideo();
    }
}
