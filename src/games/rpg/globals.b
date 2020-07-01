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
links := {};
mapName := "world1";
map := {};
const events = {};
minimap := [];

const MODES = {
    "title": {
        "init": self => initTitle(),
        "render": self => renderTitle(),
        "handleInput": self => titleInput(),
    },
    "editor": {
        "init": self => initEditor(),
        "render": self => renderEditor(),
        "isBlockVisible": (self, mx, my) => true,
        "drawViewAt": (self, x, y, mx, my, onScreen) => editorDrawViewAt(x, y, mx, my, onScreen),
        "handleInput": self => handleEditorInput(),
    },
    "game": {
        "init": self => initGame(),
        "render": self => renderGame(),
        "isBlockVisible": (self, mx, my) => gameIsBlockVisible(mx, my),
        "drawViewAt": (self, x, y, mx, my, onScreen) => gameDrawViewAt(x, y, mx, my, onScreen),
        "handleInput": self => gameInput(),
    },
    "death": {
        "init": self => initDeath(),
        "render": self => renderDeath(),
        "handleInput": self => deathInput(),
        "isBlockVisible": (self, mx, my) => 0,
        "drawViewAt": (self, x, y, mx, my, onScreen) => 0,
    }
};

mode := "title";
ticks := 0;

