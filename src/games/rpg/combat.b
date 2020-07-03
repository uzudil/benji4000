combat := {
    "monsters": [],
    "round": [],
    "roundIndex": 0,
    "roundCount": 1,
    "playerControl": false,
};

def startCombat() {
    monsters := getLiveMonsters();
    if(gameMode != COMBAT && len(monsters) > 0) {
        # trace("COMBAT START");
        gameMode := COMBAT;        
        combat.roundCount := 0;
        array_foreach(player.party, (i, p) => {
            if(i = 0) {
                p["pos"] := [player.x, player.y];
            } else {
                p["pos"] := findSpaceAround(player.x, player.y);
            }
        });
        initCombatRound();
    }
}

def initCombatRound() {
    monsters := getLiveMonsters();
    pc := array_filter(player.party, p => p.hp > 0);
    if(len(pc) = 0) {
        gameMode := MOVE;
        player.partyIndex := array_find_index(player.party, p => p.hp > 0);
        mode := "death";
        MODES[mode].render();
        updateVideo();
        return 0;
    }
    if(len(monsters) = 0) {
        gameMessage("Victory!", COLOR_GREEN);
        gameMode := MOVE;
        player.partyIndex := array_find_index(player.party, p => p.hp > 0);
        return 0;
    }
    
    combat.round := [];
    combat.roundIndex := 0;
    combat.roundCount := combat.roundCount + 1;
    array_foreach(monsters, (i, p) => { 
        combat.round[len(combat.round)] := {
            "type": "monster",
            "monster": p,
            "ap": 10,
            "target": null,
            "path": [],
            "pathIndex": 0,
        }; 
    });
    array_foreach(player.party, (i, p) => { 
        combat.round[len(combat.round)] := {
            "type": "pc",
            "pc": p,
            "ap": 10
        };
    });
    
    # todo: order by initiative
    # sort(combat.round, (a,b) => { ... });

    clearGameMessages();
    gameMessage("Beginning combat round " + combat.roundCount + "...", COLOR_RED);

    runCombatTurn();
}

def runCombatTurn() {
    combatRound := combat.round[combat.roundIndex];
    if(combatRound.type = "pc") {
        if(combatRound.pc.hp <= 0) {
            combatTurnEnd();
        } else {
            # trace("SWITCH to " + combatRound.pc.index);
            player.partyIndex := combatRound.pc.index;
            player.x := player.party[player.partyIndex].pos[0];
            player.y := player.party[player.partyIndex].pos[1];

            combat.playerControl := true;
            gameMessage("It is your turn: " + combatRound.pc.name, COLOR_MID_GRAY);
            renderGame();
            updateVideo();
        }
    } else {
        monster := combatRound.monster;
        if(monster.hp <= 0) {
            combatTurnEnd();
        } else {
            combat.playerControl := false;
            while(monster.visible && combatRound.ap > 0) {
                if(combatRound.target != null) {
                    # target died
                    if(combatRound.target.hp <= 0) {
                        combatRound.target := null;
                    }

                    # if target moved
                    if(len(combatRound.path) > 0) {
                        lastNode := combatRound.path[len(combatRound.path) - 1];
                        if(lastNode.x != combatRound.target.pos[0] || lastNode.y != combatRound.target.pos[1]) {
                            combatRound.path := [];
                        }
                    }
                }

                try := 0;
                while(try < 3 && (combatRound.target = null || len(combatRound.path) = 0)) {
                    if(combatRound.target = null) {
                        combatRound.target := choose(array_filter(player.party, p => p.hp > 0));
                        combatRound.path := [];
                    }
                    if(len(combatRound.path) = 0) {
                        getMonsterPath();                    
                        if(len(combatRound.path) > 0) {
                            gameMessage(monster.monsterTemplate.name + "'s targets " + combatRound.target.name, COLOR_MID_GRAY);
                        } else {
                            combatRound.target := null;
                        }
                    }
                    try := try + 1;
                }

                apUsed := 1;
                if(combatRound.target != null) {
                    d := getMonsterToTarget();
                    if(abs(d[0]) <= monster.monsterTemplate.range && abs(d[1]) <= monster.monsterTemplate.range) {
                        attackMonster();
                        apUsed := monster.monsterTemplate.attackAp;
                    } else {
                        if(combatRound.pathIndex < len(combatRound.path)) {
                            moveMonster();
                        }
                    }
                }

                combatRound.ap := combatRound.ap - apUsed;

                sleep(250);
                renderGame();
                updateVideo();
            }
            combatTurnEnd();
        }
    }
}

def combatTurnStep(d) {
    # spend an AP point
    combat.round[combat.roundIndex].ap := combat.round[combat.roundIndex].ap - d;
    if(combat.round[combat.roundIndex].ap <= 0) {
        combatTurnEnd();
    }
}

def combatTurnEnd() {
    # any participants left?
    pc := array_filter(player.party, p => p.hp > 0);
    live_monsters := getLiveMonsters();
    if(len(pc) = 0 || len(live_monsters) = 0) {
        initCombatRound();
    } else {
        # next creature's turn
        combat.roundIndex := combat.roundIndex + 1;
        if(combat.roundIndex >= len(combat.round)) {
            # next round
            initCombatRound();
        } else {
            runCombatTurn();
        }
    }
}

def getMonsterToTarget() {
    combatRound := combat.round[combat.roundIndex];
    return [
        combatRound.monster.pos[0] - combatRound.target.pos[0],
        combatRound.monster.pos[1] - combatRound.target.pos[1]
    ];
}

def getLiveMonsters() {
    return array_filter(map.monster, m => { 
        return m.visible && m.hp > 0; 
    });
}

def canMoveTo(mx, my) {
    if(mx >= 0 && my >= 0 && mx < map.width && my < map.height) {
        block := blocks[getBlock(mx, my).block];
        return block.blocking = false;
    }
    return false;
}

def moveMonster() {
    combatRound := combat.round[combat.roundIndex];
    monster := combatRound.monster;

    moved := false;
    pathNode := combatRound.path[combatRound.pathIndex];
    #trace("At " + monster.pos[0] + "," + monster.pos[1] + " trying: " + nx + "," + ny);
    if(canMoveTo(pathNode.x, pathNode.y)) {
        monster.pos[0] := pathNode.x;
        monster.pos[1] := pathNode.y;
        combatRound.pathIndex := combatRound.pathIndex + 1;
        moved := true;
        #trace("...yes");
    } else {
        #trace("...no");
    }

    if(moved) {
        gameMessage(monster.monsterTemplate.name + " moves", COLOR_MID_GRAY);
    } else {
        gameMessage(monster.monsterTemplate.name + " waits", COLOR_MID_GRAY);        
    }
}

def attackMonster() {
    combatRound := combat.round[combat.roundIndex];
    monster := combatRound.monster;
    gameMessage(monster.monsterTemplate.name + " attacks " + combatRound.target.name + "!", COLOR_MID_GRAY);
    dam := roll(monster.monsterTemplate.attack[0], monster.monsterTemplate.attack[1]);
    if(dam > 0) {
        gameMessage(combatRound.target.name + " takes " + dam + " damage!", COLOR_RED);
        combatRound.target.hp := max(combatRound.target.hp - dam, 0);
        if(combatRound.target.hp = 0) {
            gameMessage(combatRound.target.name + " dies!", COLOR_RED);
            pc := array_filter(player.party, p => p.hp > 0);
            if(len(pc) > 0) {
                combatRound.target := choose(pc);
            } else {
                combatTurnEnd();
            }
        }
    } else {
        gameMessage(monster.monsterTemplate.name + " misses.", COLOR_MID_GRAY);
    }
}

def playerAttacks(monster) {
    # todo: use inventory to get attack numbers, range, defense, ap-cost, etc.
    combatRound := combat.round[combat.roundIndex];
    gameMessage(combatRound.pc.name + " attacks " + monster.monsterTemplate.name + "!", COLOR_MID_GRAY);
    dam := roll(0, 4);
    if(dam > 0) {
        gameMessage(monster.monsterTemplate.name + " takes " + dam + " damage!", COLOR_RED);
        monster.hp := max(monster.hp - dam, 0);
        if(monster.hp = 0) {
            exp := monster.monsterTemplate.level * 100;
            gainExp(combatRound.pc, roll(int(exp * 0.7), exp));
            gameMessage(monster.monsterTemplate.name + " dies!", COLOR_RED);
            if(events[mapName]["onMonsterKilled"] != null) {
                events[mapName].onMonsterKilled(monster);
            }
            if(len(getLiveMonsters()) = 0) {
                combatTurnEnd();
                return 1;
            }
        }
        percent := monster.hp / monster.monsterTemplate.startHp;
        if(percent < 0.2) {
            gameMessage(monster.monsterTemplate.name + " is critical!", COLOR_RED);
        } else {
            if(percent < 0.5) {
                gameMessage(monster.monsterTemplate.name + " is wounded!", COLOR_RED);
            }
        }
    } else {
        gameMessage(combatRound.pc.name + " misses.", COLOR_MID_GRAY);
    }
    return 3;
}

def getMonsterPath() {
    combatRound := combat.round[combat.roundIndex];
    combatRound.pathIndex := 0;
    if(combatRound.target = null) {
        combatRound.path := [];
    } else {
        r := LIGHT_RADIUS * 2 - 1;
        info := {
            "grid": [],
            "start": null,
            "end": null,
        };
        traverseMapAround(
            combatRound.monster.pos[0], 
            combatRound.monster.pos[1], 
            r, 
            (px, py, x, y, mapx, mapy, onScreen, mapBlock) => {
                if(len(info.grid) <= x) {
                    info.grid[x] := [];                    
                }
                block := blocks[mapBlock.block];
                blocked := block.blocking;
                if(blocked = false) {
                    pc := array_find(player.party, p => p.pos[0] = mapx && p.pos[1] = mapy && p.hp > 0 && p.name != combatRound.target.name);
                    blocked := pc != null;
                }
                if(blocked = false) {
                    npc := array_find(map.npc, p => p.pos[0] = mapx && p.pos[1] = mapy);
                    blocked := npc != null;
                }
                if(blocked = false) {
                    m := array_find(map.monster, p => p.pos[0] = mapx && p.pos[1] = mapy && p.id != combatRound.monster.id);
                    blocked := m != null;
                }
                info.grid[x][y] := newGridNode(x, y, blocked);
                if(mapx = combatRound.monster.pos[0] && mapy = combatRound.monster.pos[1]) {
                    info.start := info.grid[x][y];
                }
                if(mapx = combatRound.target.pos[0] && mapy = combatRound.target.pos[1]) {
                    info.end := info.grid[x][y];
                }
            }
        );
        if(info.start = null || info.end = null) {
            return 1;
        }
        #trace("Looking for path, from=" + info.start + " to=" + info.end);
        path := astarSearch(info.grid, info.start, info.end);   
        dx := combatRound.monster.pos[0] - info.start.x;
        dy := combatRound.monster.pos[1] - info.start.y;
        combatRound.path := array_map(path, e => {
            return {
                "x": e.x + dx,
                "y": e.y + dy,
            };
        });
        #trace("Found path=" + array_map(combatRound.path, p => p.pos));
        #trace("path delta=" + combatRound.pathDx + "," + combatRound.pathDy);
    }
}
