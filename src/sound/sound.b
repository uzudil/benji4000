def main() {
    sample1 := makeSample([
        440, 0.1,
        550, 0.1,
        440, 0.1,
        550, 0.1,
        440, 0.1,
        440, 0.1,
        440, 0.5,
    ]);
    sample2 := makeSample([
        200, 0.25,
        100, 0.25,
        200, 0.25,
        100, 0.25,
        100, 0.5,
        100, 0.5,
    ]);

    playSample(0, sample1);
    playSample(1, sample2);

    while(anyKeyDown() = false) {
    }
}
