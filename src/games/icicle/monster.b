monsters := [];

monsterDefs := {
    "b": { "speed": 0.02, "animSpeed": 0.1, "images": [ "en1", "en2" ] },
};

const UP = 0;
const DOWN = 1;
const LEFT = 2;
const RIGHT = 3;
const ALL_DIRS = [ UP, DOWN, LEFT, RIGHT ];
const OPP_DIRS = [ DOWN, UP, RIGHT, LEFT ];
const DIRS = [
    [  0, -1 ],
    [  0,  1 ],
    [ -1,  0 ],
    [  1,  0 ],
];

# todo: this should be in a stdlib
def array_map(a, f) {
    b := [];
    i := 0;
    while(i < len(a)) {
        b[len(b)] := f(a[i]);
        i := i + 1;
    }
    return b;
}

# todo: this should be in a stdlib
def array_filter(a, f) {
    b := [];
    i := 0;
    while(i < len(a)) {
        if(f(a[i])) {
            b[len(b)] := a[i];
        }
        i := i + 1;
    }
    return b;
}

def clearMonsters() {
    i := 0;
    while(i < len(monsters)) {
        m := monsters[i];
        drawSprite(-1000, -1000, monsters[i].sprite, 0, 0, 0);
        delSprite(monsters[i].sprite);
        i := i + 1;
    }
    monsters := [];
}

def addMonster(c, x, y) {
    m := {
        "sprite": len(monsters) + 1,
        "type": c,
        "x": x,
        "y": y,
        "flipX": 0,
        "flipY": 0,
        "imgIndex": 0,
        "timer": 0,
        "dir": null,
    };
    md := monsterDefs[m.type];
    monsters[len(monsters)] := m;
    setSprite(m.sprite, array_map(md.images, s => img[s]));
}

def moveMonster(m, sx, sy) {
    if(getTicks() > m.timer) {
        md := monsterDefs[m.type];
        avail := array_filter(ALL_DIRS, d => {
            bx := int(m.x / BLOCK_W);
            by := int(m.y / BLOCK_H);
            dx := DIRS[d][0];
            dy := DIRS[d][1];
            return room.blocks[bx + dx][by + dy].block = EMPTY;
        });
        same_avail := len(array_filter(avail, d => d = m.dir)) > 0;
        if(same_avail && m.dir != null) {
            # if same dir is available, remove its opposite
            avail := array_filter(avail, d => d != OPP_DIRS[m.dir]);
        }
        new_dir := null;
        if(same_avail) {
            new_dir := m.dir;
        }
        if(len(avail) > 0 && (same_avail = false || random() > 0.8 || m.dir = null)) {
            new_dir := avail[int(random() * len(avail))];
        }
        if(new_dir != null) {
            m.dir := new_dir;
            dx := DIRS[m.dir][0];
            dy := DIRS[m.dir][1];
            if(dx = 1) {
                m.flipX := 1;
            } else {
                m.flipX := 0;
            }
            m.x := m.x + dx;
            m.y := m.y + dy;
            if(dy != 0) {
                m.x := int(m.x / BLOCK_W) * BLOCK_W + BLOCK_W/2;
            } else {
                m.y := int(m.y / BLOCK_H) * BLOCK_H + BLOCK_H/2;
            }
            drawSprite(m.x - sx * BLOCK_W, m.y - sy * BLOCK_H, m.sprite, m.imgIndex, m.flipX, m.flipY);

            # kill player
            if(checkSpriteCollision(player.sprite, m.sprite)) {
                room.playerDeath();
            }

            # kill monster
            bx := int(m.x / BLOCK_W);
            by := int(m.y / BLOCK_H);
            if(room.blocks[bx][by].block = ROCK) {
                room.blocks[bx][by].block := GEM;
                return true;
            }
        }
        
        m.imgIndex := m.imgIndex + md.animSpeed;
        if(m.imgIndex >= len(md.images)) {
            m.imgIndex := 0;
        }
        m.timer := getTicks() + md.speed;
    }
    return false;
}

def drawMonsters(sx, sy) {
    ret := false;
    i := 0;
    while(i < len(monsters)) {
        m := monsters[i];
        if(moveMonster(m, sx, sy)) {
            drawSprite(-1000, -1000, monsters[i].sprite, 0, 0, 0);
            delSprite(monsters[i].sprite);
            del monsters[i];
        } else {
            i := i + 1;
        }
    }
    return ret;
}
