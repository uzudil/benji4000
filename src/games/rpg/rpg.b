const SLOTS = [
    "head", "neck", "armor", "glove", "left", "right", "ring1", "ring2", "ranged", "cape"
];

def newChar(name, imgName) {
    eq := {};
    array_foreach(SLOTS, (s, slot) => {
        eq[slot] := null;
    });
    return {
        "name": name,
        "pos": [0, 0],
        "hp": 10,
        "startHp": 10,
        "image": img[imgName],
        "exp": 0,
        "level": 1,
        "str": roll(15, 20),
        "dex": roll(15, 20),
        "speed": roll(15, 20),
        "int": roll(15, 20),
        "wis": roll(15, 20),
        "cha": roll(15, 20),
        "luck": roll(15, 20),
        "equipment": eq,        
    };
}

def getNextLevelExp(pc) {
    nextLevel := 500;
    i := 1;
    while(i < pc.level + 1) {
        nextLevel := nextLevel * 2;
        i := i + 1;
    }
    trace("For level " + i + " " + pc.name + " needs " + nextLevel + " exp points. Has: " + pc.exp);
    return nextLevel;
}

def gainExp(pc, amount) {
    pc.exp := pc.exp + amount;    
    while(pc.exp >= getNextLevelExp(pc)) {
        pc.level := pc.level + 1;
        gameMessage(pc.name + " is now level " + pc.level + "!");
    }
}

def gainHp(pc, amount) {
    pc.hp := min(pc.hp + amount, pc.startHp * pc.level);
}
