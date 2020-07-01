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
        gameMode := COMBAT;        
        combat.roundCount := 0;
        array_foreach(player.party, (i, p) => {
            p["pos"] := [ player.x, player.y ];
        });
        initCombatRound();
    }
}

def initCombatRound() {
    monsters := getLiveMonsters();
    pc := array_filter(player.party, p => p.hp > 0);
    if(len(pc) = 0) {
        gameMode := MOVE;
        player.partyIndex := 0;
        mode := "death";
        return 0;
    }
    if(len(monsters) = 0) {
        gameMessage("Victory!", COLOR_GREEN);
        gameMode := MOVE;
        # todo: should be the index of the first alive party member
        player.partyIndex := 0;
        return 0;
    }
    
    combat.round := [];
    combat.roundIndex := 0;
    combat.roundCount := combat.roundCount + 1;
    array_foreach(player.party, (i, p) => { 
        combat.round[len(combat.round)] := {
            "type": "pc",
            "pc": p,
            "ap": 10
        };
    });
    array_foreach(monsters, (i, p) => { 
        combat.round[len(combat.round)] := {
            "type": "monster",
            "monster": p,
            "ap": 10,
            "target": choose(pc),
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
            player.partyIndex := combatRound.pc.index;
            player.x := player.party[player.partyIndex].pos[0];
            player.y := player.party[player.partyIndex].pos[1];
            combat.playerControl := true;
            gameMessage("It is your turn: " + player.party[player.partyIndex].name, COLOR_MID_GRAY);
        }
    } else {
        monster := combatRound.monster;
        combat.playerControl := false;
        gameMessage(monster.monsterTemplate.name + "'s targets " + combatRound.target.name, COLOR_MID_GRAY);
        while(monster.visible && combatRound.ap > 0) {
            d := getMonsterToTarget();
            if(abs(d[0]) <= 1 && abs(d[1]) <= 1) {
                attackMonster();
                combatRound.ap := combatRound.ap - monster.monsterTemplate.attackAp;
            } else {
                moveMonster();
                combatRound.ap := combatRound.ap - 1;
            }
            sleep(500);
            renderGame();
            updateVideo();
        }
        combatTurnEnd();    
    }
}

def combatTurnStep() {
    # spend an AP point
    combat.round[combat.roundIndex].ap := combat.round[combat.roundIndex].ap - 1;
    if(combat.round[combat.roundIndex].ap <= 0) {
        combatTurnEnd();
    }
}

def combatTurnEnd() {
    # next creature's turn
    combat.roundIndex := combat.roundIndex + 1;
    if(combat.roundIndex >= len(combat.round)) {
        # next round
        initCombatRound();
    } else {
        runCombatTurn();
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

    dir := getMonsterToTarget();
    moved := false;
    if(dir[0] != 0) {
        d := dir[0] / abs(dir[0]);
        if(canMoveTo(monster.pos[0] - d, monster.pos[1])) {
            monster.pos[0] := monster.pos[0] - d;
            moved := true;
        }
    }
    if(moved = false && dir[1] != 0) {
        d := dir[1] / abs(dir[1]);
        if(canMoveTo(monster.pos[0], monster.pos[1] - d)) {
            monster.pos[1] := monster.pos[1] - d;
            moved := true;
        }
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
