def main() {
    s := "abcdef";
    print("s=" + s + " length=" + len(s));

    print("substring w/o length: " + substr(s, 2));
    print("substring w length: " + substr(s, 2, 3));

    s := "get key";
    print(">" + substr(s, 0, 4) + "<");
    print(">" + substr(s, 4) + "<");

    s := "replace THIS in this sentence";
    print("> " + replace(s, "THIS", "THAT"));
}
