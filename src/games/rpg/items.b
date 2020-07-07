const OBJECT_FOOD = "food";
const OBJECT_DRINK = "drink";
const OBJECT_POTION = "potion";
const OBJECT_ARMOR = "armor";
const OBJECT_WEAPON = "weapon";
const OBJECT_SUPPLIES = "supplies";

const ITEMS = [
    {
        "name": "Moldy cheese",
        "price": 2,
        "type": OBJECT_FOOD,
    },
    {
        "name": "Loaf of bread",
        "price": 3,
        "type": OBJECT_FOOD,
    },
    {
        "name": "Roast chicken",
        "price": 5,
        "type": OBJECT_FOOD,
    },
    {
        "name": "Rare steak",
        "price": 7,
        "type": OBJECT_FOOD,
    },
    {
        "name": "Chocolate",
        "price": 3,
        "type": OBJECT_FOOD,
    },    
    {
        "name": "Watery beer",
        "price": 1,
        "type": OBJECT_DRINK,
    },
    {
        "name": "Ogrebreath Ale",
        "price": 3,
        "type": OBJECT_DRINK,
    },
    {
        "name": "Green wine",
        "price": 3,
        "type": OBJECT_DRINK,
    },
    {
        "name": "Water",
        "price": 1,
        "type": OBJECT_DRINK,
    },
    {
        "name": "Leather gloves",
        "price": 3,
        "type": OBJECT_ARMOR,
    },
    {
        "name": "Leather boots",
        "price": 4,
        "type": OBJECT_ARMOR,
    },
    {
        "name": "Leather armor",
        "price": 12,
        "type": OBJECT_ARMOR,
    },
    {
        "name": "Leather pants",
        "price": 8,
        "type": OBJECT_ARMOR,
    },
    {
        "name": "Leather helm",
        "price": 7,
        "type": OBJECT_ARMOR,
    },
    {
        "name": "Dagger",
        "price": 7,
        "type": OBJECT_WEAPON,
    },
    {
        "name": "Small sword",
        "price": 8,
        "type": OBJECT_WEAPON,
    },
    {
        "name": "Soldier's sword",
        "price": 15,
        "type": OBJECT_WEAPON,
    },
    {
        "name": "Battle Axe",
        "price": 16,
        "type": OBJECT_WEAPON,
    },
    {
        "name": "Warhammer",
        "price": 15,
        "type": OBJECT_WEAPON,
    },
    {
        "name": "Torch",
        "price": 2,
        "type": OBJECT_SUPPLIES,
    },
    {
        "name": "Lockpick",
        "price": 3,
        "type": OBJECT_SUPPLIES,
    },
    {
        "name": "Rope",
        "price": 4,
        "type": OBJECT_SUPPLIES,
    },
    {
        "name": "Small round potion",
        "price": 3,
        "type": OBJECT_POTION,
        "onAction": (self, pc) => gainHp(pc, 10),
    },
    {
        "name": "Large round potion",
        "price": 12,
        "type": OBJECT_POTION,
        "onAction": (self, pc) => gainHp(pc, 35),
    },
];

ITEMS_BY_TYPE := {};
ITEMS_BY_NAME := {};

def initItems() {
    array_foreach(ITEMS, (index, item) => {
        item["sellPrice"] := max(int(item.price * 0.75), 1);
        if(ITEMS_BY_TYPE[item.type] = null) {
            ITEMS_BY_TYPE[item.type] := [];
        }
        ITEMS_BY_TYPE[item.type][len(ITEMS_BY_TYPE[item.type])] := item;
        ITEMS_BY_NAME[item.name] := item;
    });
}

def getRandomItem(types) {
    type := choose(types);
    return choose(ITEMS_BY_TYPE[type]);
}

def itemInstance(item) {
    return {
        "name": item.name,
        "quality": 100,
        "uses": 0,
    };
}
