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
        "attack": [],
        "armor": 0,
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

def calculateArmor(pc) {
    invArmor := array_map(array_filter(SLOTS, slot => {
        if(pc.equipment[slot] != null) {
            return ITEMS_BY_NAME[pc.equipment[slot].name]["ac"] != null;
        }
        return false;
    }), slot => pc.equipment[slot]);
    pc.armor := array_reduce(invArmor, 0, (value, invItem) => {
        return value + ITEMS_BY_NAME[invItem.name].ac;
    });
    invWeapons := getWeapons(pc);
    pc.attack := array_map(invWeapons, invItem => ITEMS_BY_NAME[invItem.name].dam);
}

def getWeapons(pc) {
    return array_map(array_filter(SLOTS, slot => {
        if(pc.equipment[slot] != null) {
            return ITEMS_BY_NAME[pc.equipment[slot].name]["dam"] != null;
        }
        return false;
    }), slot => pc.equipment[slot]);
}
