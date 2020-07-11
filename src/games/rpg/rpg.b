def newChar(name, imgName) {
    eq := {};
    array_foreach(SLOTS, (s, slot) => {
        eq[slot] := null;
    });
    pc := {
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
    calculateArmor(pc);
    return pc;
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
        gameMessage(pc.name + " is now level " + pc.level + "!", COLOR_GREEN);
    }
}

def gainHp(pc, amount) {
    pc.hp := min(pc.hp + amount, pc.startHp * pc.level);
}

def calculateArmor(pc) {
    armorBonus := max(0, pc.dex - 15) + max(0, pc.speed - 17);
    invArmor := array_map(array_filter(SLOTS, slot => {
        if(pc.equipment[slot] != null) {
            return ITEMS_BY_NAME[pc.equipment[slot].name]["ac"] != null;
        }
        return false;
    }), slot => pc.equipment[slot]);
    pc.armor := array_reduce(invArmor, armorBonus, (value, invItem) => {
        return value + ITEMS_BY_NAME[invItem.name].ac;
    });

    attackBonus := int(pc.level / 2) + max(0, pc.str - 17) + max(0, pc.dex - 17);
    invWeapons := getWeapons(pc);
    pc.attack := array_map(invWeapons, invItem => {
        dam := ITEMS_BY_NAME[invItem.name].dam;
        return {
            "dam": [dam[0] + attackBonus, dam[1] + attackBonus],
            "weapon": invItem.name,
        };
    });
    if(len(invWeapons) = 0) {
        pc.attack := [ {
            "dam": [attackBonus, attackBonus + 2],
            "weapon": "Bare hands",
        } ];
    }
}

def getWeapons(pc) {
    return array_map(array_filter(SLOTS, slot => {
        if(pc.equipment[slot] != null) {
            return ITEMS_BY_NAME[pc.equipment[slot].name]["dam"] != null;
        }
        return false;
    }), slot => pc.equipment[slot]);
}
