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

