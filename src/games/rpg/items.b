const OBJECT_FOOD = "food";
const OBJECT_DRINK = "drink";
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
];

ITEMS_BY_TYPE := {};

def initItems() {
    array_foreach(ITEMS, (index, item) => {
        if(ITEMS_BY_TYPE[item.type] = null) {
            ITEMS_BY_TYPE[item.type] := [];
        }
        ITEMS_BY_TYPE[item.type][len(ITEMS_BY_TYPE[item.type])] := item;
    });
}

def getRandomItem(types) {
    type := choose(types);
    return choose(ITEMS_BY_TYPE[type]);
}
