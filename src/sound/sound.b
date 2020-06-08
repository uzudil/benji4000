const freqC = 523.3;
const freqE = 659.3;
const freqG = 784.0;

def main() {

        

    playSound(0, freqC, 0.2);
    playSound(0, freqE, 0.2);
    playSound(0, freqC, 0.2);
    playSound(0, freqE, 0.2);
    playSound(0, freqC, 0.3);
    playSound(0, freqC, 0.3);
    playSound(0, freqC, 0.3);


    playSound(1, freqG, 0.5);    
    playSound(1, freqE, 0.5);    
    playSound(1, freqG, 0.5);    
    playSound(1, freqE, 0.5);    
    playSound(1, freqG, 0.5);    
    playSound(1, freqE, 0.5);    

    while(anyKeyDown() = false) {
    }
}
