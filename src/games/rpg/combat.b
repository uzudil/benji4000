combat := {
    "monsters": [],
    "round": [],
    "roundIndex": 0,
    "roundCount": 1,
    "playerControl": false,
};

def startCombat() {
    if(gameMode = MOVE && mode != "death") {
        player.party[player.partyIndex].pos[0] := player.x;
        player.party[player.partyIndex].pos[1] := player.y;
        monsters := getLiveMonsters(player.party[player.partyIndex]);
        if(len(monsters) > 0) {
            # position party
            array_foreach(player.party, (i, p) => {
                if(i = 0) {
                    p["pos"] := [player.x, player.y];
                } else {
                    p["pos"] := findSpaceAround(player.x, player.y);
                }
            });
            # trace("COMBAT START");
            gameMode := COMBAT;        
            combat.roundCount := 0;
            combat.monsters := monsters;
            initCombatRound();
        }
    }
}

def initCombatRound() {
    combat.round := [];
    combat.roundIndex := 0;
    combat.roundCount := combat.roundCount + 1;
    array_foreach(combat.monsters, (i, p) => { 
        combat.round[len(combat.round)] := {
            "type": "monster",
            "monster": p,
            "ap": 10,
            "target": null,
            "path": p.path,
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

def checkCombatDone() {
    pc := array_filter(player.party, p => p.hp > 0);
    if(len(pc) = 0) {
        gameMode := MOVE;
        player.partyIndex := 0;
        mode := "death";
        MODES[mode].render();
        updateVideo();
        return true;
    }
    live_monsters := array_filter(combat.monsters, m => m.visible && m.hp > 0);
    if(len(live_monsters) = 0) {
        gameMessage("Victory!", COLOR_GREEN);
        gameMode := MOVE;
        player.partyIndex := array_find_index(player.party, p => p.hp > 0);
        return true;
    }
    return false;
}

def runCombatTurn() {

    if(checkCombatDone()) {
        return 1;
    }

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
                
                # target still valid?
                if(combatRound.target != null) {
                    # target died
                    if(combatRound.target.hp <= 0) {
                        combatRound.target := null;
                    }

                    # if target moved: retarget
                    if(combatRound.target != null && len(combatRound.path) > 0) {
                        lastNode := combatRound.path[len(combatRound.path) - 1];
                        if(lastNode.x != combatRound.target.pos[0] || lastNode.y != combatRound.target.pos[1]) {
                            #trace("target moved: retargeting");
                            combatRound.path := findPath(monster, combatRound.target);
                            combatRound.pathIndex := 0;
                        }
                    }
                }

                apUsed := 1;
                near_pc := array_find(player.party, pc => {
                    d := [
                        monster.pos[0] - pc.pos[0],
                        monster.pos[1] - pc.pos[1]
                    ];
                    near := abs(d[0]) <= monster.monsterTemplate.range && abs(d[1]) <= monster.monsterTemplate.range;
                    if(monster.target != null) {
                        return pc.name = monster.target.name && near;
                    } else {
                        return near;
                    }
                });
                if(near_pc != null) {
                    attackMonster(near_pc);
                    apUsed := monster.monsterTemplate.attackAp;
                } else {
                    if(combatRound.pathIndex < len(combatRound.path)) {
                        # move along path
                        if(moveMonster() = false) {
                            # if blocked (by another monster), end path
                            combatRound.pathIndex := len(combatRound.path);
                        }
                    }

                    if(combatRound.pathIndex >= len(combatRound.path)) {
                        # try to find a new target
                        combatRound.pathIndex := 0;
                        combatRound.path := [];
                        try := 0;
                        while(try < 3 && len(combatRound.path) = 0) {
                            combatRound.target := choose(array_filter(player.party, p => p.hp > 0));
                            if(combatRound.target != null) {
                                #trace("new target: finding path target=" + combatRound.target.index + " from=" + monster.pos + " to=" + combatRound.target.pos);
                                combatRound.path := findPath(monster, combatRound.target);
                                combatRound.pathIndex := 0;
                            }
                            try := try + 1;
                        }

                        # if we can't find a path, skip rest of turn
                        if(len(combatRound.path) = 0) {
                            apUsed := combatRound.ap;
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
    if(checkCombatDone() = false) {
        # spend an AP point
        combat.round[combat.roundIndex].ap := combat.round[combat.roundIndex].ap - d;
        if(combat.round[combat.roundIndex].ap <= 0) {
            combatTurnEnd();
        }
    }
}

def combatTurnEnd() {
    # any participants left?
    pc := array_filter(player.party, p => p.hp > 0);
    live_monsters := array_filter(combat.monsters, m => m.visible && m.hp > 0);
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

def getLiveMonsters(pc) {
    return array_filter(map.monster, m => { 
        if(m.visible && m.hp > 0) {
            #trace("live? finding path to " + pc.index + " pos=" + pc.pos);
            m["path"] := findPath(m, pc);
            return len(m.path) > 0;
        } else {
            return false;
        }
    });
}

def canMoveTo(monster, mx, my) {
    if(mx >= 0 && my >= 0 && mx < map.width && my < map.height) {
        block := blocks[getBlock(mx, my).block];
        blocked := block.blocking;
        if(blocked = false) {
            npc := array_find(map.npc, p => p.pos[0] = mx && p.pos[1] = my);
            blocked := npc != null;
        }
        if(blocked = false) {
            m := array_find(map.monster, p => p.pos[0] = mx && p.pos[1] = my && p.id != monster.id && p.hp > 0);
            blocked := m != null;
        }
        return blocked = false;
    }
    return false;
}

def moveMonster() {
    combatRound := combat.round[combat.roundIndex];
    monster := combatRound.monster;

    moved := false;
    pathNode := combatRound.path[combatRound.pathIndex];
    #trace("At " + monster.pos[0] + "," + monster.pos[1] + " trying: " + nx + "," + ny);
    if(canMoveTo(monster, pathNode.x, pathNode.y)) {
        monster.pos[0] := pathNode.x;
        monster.pos[1] := pathNode.y;
        combatRound.pathIndex := combatRound.pathIndex + 1;
        moved := true;
        #trace("...yes");
    } else {
        #trace("...no");
    }

    if(moved) {
        #gameMessage(monster.monsterTemplate.name + " moves", COLOR_MID_GRAY);
    } else {
        gameMessage(monster.monsterTemplate.name + " waits", COLOR_MID_GRAY);        
    }
    return moved;
}

def attackMonster(targetPc) {
    combatRound := combat.round[combat.roundIndex];
    monster := combatRound.monster;
    gameMessage(monster.monsterTemplate.name + " attacks " + targetPc.name + "!", COLOR_MID_GRAY);
    dam := roll(monster.monsterTemplate.attack[0], monster.monsterTemplate.attack[1]);
    if(dam > 0) {
        gameMessage(targetPc.name + " takes " + dam + " damage!", COLOR_RED);
        targetPc.hp := max(targetPc.hp - dam, 0);
        if(targetPc.hp = 0) {
            gameMessage(targetPc.name + " dies!", COLOR_RED);
            pc := array_filter(player.party, p => p.hp > 0);
            if(len(pc) = 0) {
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
        } else {
            percent := monster.hp / monster.monsterTemplate.startHp;
            if(percent < 0.2) {
                gameMessage(monster.monsterTemplate.name + " is critical!", COLOR_RED);
            } else {
                if(percent < 0.5) {
                    gameMessage(monster.monsterTemplate.name + " is wounded!", COLOR_RED);
                }
            }
        }
    } else {
        gameMessage(combatRound.pc.name + " misses.", COLOR_MID_GRAY);
    }
    return 3;
}

def findPath(monster, target) {
    #trace("monster=" + monster + " target=" + target);
    r := LIGHT_RADIUS * 2 - 1;
    info := {
        "grid": [],
        "start": null,
        "end": null,
    };
    traverseMapAround(
        monster.pos[0], 
        monster.pos[1], 
        r, 
        (px, py, x, y, mapx, mapy, onScreen, mapBlock) => {
            if(len(info.grid) <= x) {
                info.grid[x] := [];                    
                    info.grid[x] := [];                    
                info.grid[x] := [];                    
                    info.grid[x] := [];                    
                info.grid[x] := [];                    
            }
            info.grid[x][y] := newGridNode(x, y, canMoveTo(monster, mapx, mapy) = false);
            if(mapx = monster.pos[0] && mapy = monster.pos[1]) {
                info.start := info.grid[x][y];
            }
            if(mapx = target.pos[0] && mapy = target.pos[1]) {
                info.end := info.grid[x][y];
            }
        }
    );
    if(info.start = null || info.end = null) {
        return [];
    }
    #trace("Looking for path, from=" + info.start + " to=" + info.end);
    path := astarSearch(info.grid, info.start, info.end);   
    dx := monster.pos[0] - info.start.x;
    dy := monster.pos[1] - info.start.y;
    path := array_map(path, e => {
        return {
            "x": e.x + dx,
            "y": e.y + dy,
        };
    });
    #trace("Found path=" + array_map(combatRound.path, p => p.pos));
    #trace("path delta=" + combatRound.pathDx + "," + combatRound.pathDy);
    return path;
}
