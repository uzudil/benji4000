const freqC = 523.3;
const freqE = 659.3;
const freqG = 784.0;

def main() {
    i := 100;
    while(i < 900) {
        playSound(0, i, 0.1);
        i := i + 100;
    }
    while(i > 100) {
        playSound(0, i, 0.1);
        i := i - 100;
    }    
    while(anyKeyDown() = false) {
    }
}
