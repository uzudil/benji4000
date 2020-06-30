combat := {
    "monsters": [],
    "round": [],
    "roundIndex": 0,
    "roundCount": 1,
    "playerControl": false,
};

def startCombat(monsters) {
    if(gameMode = COMBAT) {
        return false;
    }
    gameMode := COMBAT;
    combat.monsters := monsters;
    combat.roundCount := 0;

    initCombatRound();
}

def initCombatRound() {
    combat.round := [];
    combat.roundIndex := 0;
    combat.roundCount := combat.roundCount + 1;
    array_foreach(player.party, (i, p) => { 
        combat.round[len(combat.round)] := {
            "type": "pc",
            "index": i,
            "ap": 10
        };
    });
    array_foreach(combat.monsters, (i, p) => { 
        combat.round[len(combat.round)] := {
            "type": "monster",
            "index": i,
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
    trace("runCombatTurn");
    if(combat.round[combat.roundIndex].type = "pc") {
        player.partyIndex := combat.round[combat.roundIndex].index;
        combat.playerControl := true;
        gameMessage("It is " + player.party[player.partyIndex].name + "'s turn.", COLOR_MID_GRAY);
    } else {
        combatRound := combat.round[combat.roundIndex];
        monster := map.monster[combatRound.index];
        combat.playerControl := false;
        monster_template := array_find(MONSTERS, m => m.block = blocks[monster.block].img);
        gameMessage(monster_template.name + "'s turn...", COLOR_MID_GRAY);
        while(combatRound.ap > 0) {
            dx := monster.pos[0] - player.x;
            dy := monster.pos[1] - player.y;
            if(abs(dx) <= 1 && abs(dy) <= 1) {
                gameMessage(monster_template.name + " attacks " + player.party[player.partyIndex].name + "!", COLOR_MID_GRAY);
            } else {
                ox := monster.pos[0];
                oy := monster.pos[1];
                if(abs(dx) > 1) {
                    monster.pos[0] := monster.pos[0] - (dx/abs(dx));
                } else {
                    monster.pos[1] := monster.pos[1] - (dy/abs(dy));
                }
                trace("pos=" + monster.pos[0] + "/" + monster.pos[1] + " d=" + dx + "/" + dy + " old=" + ox + "/" + oy);
                block := blocks[getBlock(monster.pos[0], monster.pos[1]).block];
                if(block.blocking || monster.pos[0] < 0 || monster.pos[1] < 0 || monster.pos[0] >= map.width || monster.pos[1] >= map.height) {
                    monster.pos[0] := ox;
                    monster.pos[1] := oy;
                    gameMessage(monster_template.name + " waits", COLOR_MID_GRAY);
                } else {
                    gameMessage(monster_template.name + " moves", COLOR_MID_GRAY);
                }
            }
            sleep(1000);            
            combatRound.ap := combatRound.ap - 1;
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
