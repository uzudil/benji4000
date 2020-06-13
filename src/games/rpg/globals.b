const TILE_W = 16;
const TILE_H = 16;
const MAP_VIEW_W = 11;
const MAP_VIEW_H = 11;

const MODE_GAME = 0;
const MODE_EDIT = 1;

const WATER = 0;
const GRASS = 1;
const EDGE = 2;
const CORNER = 3;
const TURN = 4;
const MOUNTAIN = 5;

img := null;
blocks := [
    {
        "img": "water",
        "isEdge": false,
        "blocking": true,
        "color": COLOR_DARK_BLUE,
    },
    {
        "img": "grass",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_GREEN,
    },
    {
        "img": "coast",
        "isEdge": true,
        "blocking": false,
        "color": COLOR_BROWN,
    },
    {
        "img": "coastcorner",
        "isEdge": true,
        "blocking": false,
        "color": COLOR_BROWN,
    },
    {
        "img": "coastturn",
        "isEdge": true,
        "blocking": false,
        "color": COLOR_BROWN,
    },
    {
        "img": "mtn5",
        "isEdge": false,
        "blocking": true,
        "color": COLOR_MID_GRAY,
    },
    {
        "img": "mtn3",
        "isEdge": false,
        "blocking": true,
        "color": COLOR_WHITE,
    },
    {
        "img": "mtn4",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_WHITE,
    },
    {
        "img": "road1",
        "isEdge": false,
        "blocking": false,
        "color": COLOR_DARK_GRAY,
    },

];
map := {};
player := {
    "x": 50,
    "y": 50,
    "map": "world",
};

const MODES = {
    "editor": {
        "init": self => initEditor(),
        "render": self => renderEditor(),
        "renderMapCursor": (self, x, y) => renderEditorMapCursor(x, y),
        "handleInput": self => handleEditorInput(),
    },
    "game": {
        "init": self => loadMap("world"),
        "render": self => renderGame(),
        "renderMapCursor": (self, x, y) => trace("implement me: renderMapCursor"),
        "handleInput": (self, x, y) => trace("implement me: handleInput"),
    }
};

mode := "editor";
ticks := 0;

# todo: move to lib
def array_find_index(array, fx) {
    i := 0; 
    while(i < len(array)) {
        if(fx(array[i])) {
            return i;
        }
        i := i + 1;
    }
    return -1;
}

def getBlockIndex(name) {
    return array_find_index(blocks, b => b.img = name);
}
