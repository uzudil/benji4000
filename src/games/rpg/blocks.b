def randomBlockOfType(type) {
    bb := array_filter(blocks, b => b.type = type);
    return bb[random() * len(bb)];
}

def initBlocks() {
    i := 0;
    while(i < len(blocks)) {
        blocks[i]["index"] := i;
        i := i + 1;
    }
}

def getBlockIndexByName(name) {
    return array_find_index(blocks, b => b.img = name);
}

blocks := [
    {
        "img": "water",
        "type": "water",
        "isEdge": false,
        "blocking": true,
        "color": COLOR_DARK_BLUE,
    },
    {
        "img": "grass",
        "type": "grass",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_GREEN,
    },
    {
        "img": "coast",
        "type": "edge",
        "isEdge": true,
        "blocking": false,
        "color": COLOR_BROWN,
    },
    {
        "img": "coastcorner",
        "type": "corner",
        "isEdge": true,
        "blocking": false,
        "color": COLOR_BROWN,
    },
    {
        "img": "coastturn",
        "type": "turn",
        "isEdge": true,
        "blocking": false,
        "color": COLOR_BROWN,
    },
    {
        "img": "mtn5",
        "type": "mountain",
        "isEdge": false,
        "blocking": true,
        "color": COLOR_MID_GRAY,
    },
    {
        "img": "mtn3",
        "type": "mountain",
        "isEdge": false,
        "blocking": true,
        "color": COLOR_WHITE,
    },
    {
        "img": "mtn4",
        "type": "hill",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_WHITE,
    },
    {
        "img": "road1",
        "type": "roadend",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_DARK_GRAY,
    },
    {
        "img": "road2",
        "type": "road2",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_DARK_GRAY,
    },
    {
        "img": "road3",
        "type": "road3",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_DARK_GRAY,
    },
    {
        "img": "road4",
        "type": "road4",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_DARK_GRAY,
    },
    {
        "img": "road5",
        "type": "road",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_DARK_GRAY,
    },
    {
        "img": "treesm",
        "type": "tree-small",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_TEAL,
    },
    {
        "img": "treesm2",
        "type": "tree-small",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_TEAL,
    },
    {
        "img": "castle",
        "type": "castle",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_RED,
    },
    {
        "img": "swamp",
        "type": "swamp",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_GREEN,
    },
    {
        "img": "village",
        "type": "village",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_RED,
    },
    {
        "img": "cave",
        "type": "cave",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_RED,
    },
    {
        "img": "fighter1",
        "type": "fighter",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_RED,
    },
    {
        "img": "brick2",
        "type": "brick",
        "isEdge": false,
        "blocking": true,
        "color": COLOR_RED,
    },
    {
        "img": "brick",
        "type": "brickdoor",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_RED,
    },
    {
        "img": "space",
        "type": "space",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_BLACK,
    },
    {
        "img": "floor1",
        "type": "floor1",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_BROWN,
    },
    {
        "img": "floor2",
        "type": "floor2",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_LIGHT_GRAY,
    },

];
