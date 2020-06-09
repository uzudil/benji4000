const freqC = 523.3;
const freqE = 659.3;
const freqG = 784.0;

def main() {
    i := 0;
    while(i < 100) {
        if(i % 2 = 0) {
            playSound(0, 50, 0.5);
        } else {
            playSound(0, 70, 0.5);
        }
        i := i + 1;
    }
    playSound(1, 0, 2);
    f := 200;
    while(f < 440) {
        playSound(1, f, 0.1);
        f := f + 10;
    }
    while(anyKeyDown() = false) {
    }
}
