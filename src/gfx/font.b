def main() {
    setVideoMode(0);

    print("char 33 is currently: !");
    print("value=" + getFont(33));

    setFont(33, [ 24, 36, 66, 44, 52, 66, 36, 24 ]);
    print("after update: !");

    input("try it: ");
}
