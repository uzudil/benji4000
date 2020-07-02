playerName := "Anonymous";
player := {
    "x": 18,
    "y": 4,
    "map": "bonefell",
    "blockIndex": 0,
    "messages": [],
    "gameState": {},
    "blocks": {},
    "traders": {},
    "inventory": [],
    "coins": 10,
    "messagePaging": false,
    "monster": {},
    "party": [],
    "partyIndex": 0,
};

const LIGHT_RADIUS = 15;

const MOVE = 1;
const CONVO = 2;
const TRADE = 3;
const COMBAT = 4;
gameMode := MOVE;
tradeMode := null;
moreText := false;

convo := {
    "npc": null,
    "map": null,
    "key": null,
    "answers": [],
};

def initGame() {
    # init the maps
    events["almoc"] := events_almoc;
    events["bonefell"] := events_bonefell;
    events["redclaw"] := events_redclaw;
    events["world1"] := events_world1;

    initItems();

    savegame := load("savegame.dat");
    if(savegame = null) {
        gameMessage("You awake underground surrounded by damp earth and old bones. Press H any time for help.", COLOR_YELLOW);
        c := newChar(playerName, "fighter1");
        c["index"] := 0;
        player.party[0] := c;

        # for combat testing
        i := 1;
        while(i < 4) {
            name := choose(["fighter1", "robes2", "robes", "man1", "man2", "woman1", "woman2"]);
            c := newChar(name, name);
            c["index"] := i;
            player.party[len(player.party)] := c;
            i := i + 1;
        }      
    } else {
        player := savegame;
        player.partyIndex := array_find_index(player.party, p => p.hp > 0);
        player.messages := [];
        gameMessage("You continue on your adventure.", COLOR_WHITE);
    }
    player.blockIndex := getBlockIndexByName("fighter1");
    player["image"] := img[blocks[player.blockIndex].img];
    mapName := player.map;
    gameLoadMap(mapName);
}

def gameLoadMap(name) {
    loadMap(name);    
    applyGameBlocks(name);
    array_foreach(map.monster, (i, e) => {
        e["image"] := img[blocks[e.block].img];
        e["start"] := [e.pos[0], e.pos[1]];
        e["id"] := "" + e.pos[0] + "," + e.pos[1];
        e["visible"] := false;
        e["monsterTemplate"] := array_find(MONSTERS, m => m.block = blocks[e.block].img);

        if(player.monster[name] = null) {
            player.monster[name] := {};
        }
        if(player.monster[name][e.id] != null) {
            e["hp"] := player.monster[name][e.id].hp;
            e["pos"] := player.monster[name][e.id].pos;
        } else {
            e["hp"] := e.monsterTemplate.startHp;
        }
    });
    array_foreach(map.npc, (i, e) => {
        e["image"] := img[blocks[e.block].img];
        e["start"] := [e.pos[0], e.pos[1]];

        # init trade
        if(player.traders[name] = null) {
            player.traders[name] := {};
        }
        if(events[name]["onTrade"] != null) {
            trade := events[name].onTrade(e);
            if(trade != null) {
                if(player.traders[name][e.name] = null) {
                    player.traders[name][e.name] := [];
                }
                inv := player.traders[name][e.name];
                while(len(inv) < 5) {
                    inv[len(inv)] := itemInstance(getRandomItem(trade));
                }
            }
        }
        saveGame();
    });
}

def drawUI() {
    clearVideo();

    color := COLOR_DARK_BLUE;
    if(gameMode = CONVO || gameMode = TRADE) {
        color := COLOR_TEAL;
    }
    if(gameMode = COMBAT) {
        color := COLOR_RED;
    }

    drawRect(4, 5, 5 + TILE_W * MAP_VIEW_W, 5 + TILE_H * MAP_VIEW_H, color);

    # pc-s
    x := 10 + TILE_W * MAP_VIEW_W;
    y := 5;
    drawRect(x, y, x + (320 - x - 5), 45, color);
    array_foreach(player.party, (i, p) => {
        color := COLOR_MID_GRAY;
        if(gameMode = COMBAT) {
            if(combat.round[combat.roundIndex].type = "pc") {
                if(combat.round[combat.roundIndex].pc.index = i) {
                    color := COLOR_YELLOW;
                }
            }
        }
        drawColoredText(x + 2, y + 2 + i * 10, color, COLOR_BLACK, substr(p.name, 0, 9));
        drawColoredText(x + 82, y + 2 + i * 10, color, COLOR_BLACK, "H" + p.hp);
    });

    # show AP
    if(gameMode = COMBAT) {
        if(combat.playerControl) {
            apColor := COLOR_GREEN;
        } else {
            apColor := COLOR_MID_GRAY;
        }
        combatRound := combat.round[combat.roundIndex];
        drawText(5, 10 + TILE_H * MAP_VIEW_H, apColor, COLOR_BLACK, "AP:");
        fillRect(
            30, 
            12 + TILE_H * MAP_VIEW_H, 
            30 + max(0, (combatRound.ap/10))*(TILE_W * MAP_VIEW_W - 30), 
            15 + TILE_H * MAP_VIEW_H, 
            apColor);
    }

    # party info
    y := 50;
    message_y := 81;
    drawRect(x, y, x + (320 - x - 5), message_y - 5, color); 
    drawColoredText(x + 5, y + 5, COLOR_MID_GRAY, COLOR_BLACK, "Coins _1_$" + player.coins);

    # messages
    y := message_y;
    drawRect(x, y, x + (320 - x - 5), y + ((5 + TILE_H * MAP_VIEW_H) - y), color); 
    drawGameMessages(x, message_y + 90);

    # trading
    if(gameMode = CONVO) {        
        if(tradeMode = "_buy_") {
            drawText(10, 10, COLOR_WHITE, COLOR_BLACK, "Inventory of " + convo.npc.name);
            drawColoredText(10, 25, COLOR_MID_GRAY, COLOR_BLACK, "_7_1 Leave store");
            array_foreach(player.traders[mapName][convo.npc.name], (i, item) => {
                drawColoredText(10, 35 + i * 10, COLOR_MID_GRAY, COLOR_BLACK, 
                    "_7_" + (i + 2) + " " + item.name + " " + "$" + ITEMS_BY_NAME[item.name].price);
            });
            
        }
        if(tradeMode = "_sell_") {
            drawText(10, 10, COLOR_WHITE, COLOR_BLACK, "Party Inventory");
            drawColoredText(10, 25, COLOR_MID_GRAY, COLOR_BLACK, "_7_1 Leave store");
            array_foreach(player.inventory, (i, item) => {
                drawColoredText(10, 35 + i * 10, COLOR_MID_GRAY, COLOR_BLACK, 
                    "_7_" + (i + 2) + " " + item.name + " " + "$" + ITEMS_BY_NAME[item.name].sellPrice);
            });
        }
    }
}

def renderGame() {
    drawUI();
    initLight();
    if(gameMode = MOVE) {        
        moveNpcs();
    }
    if(tradeMode = null) {
        mx := player.x;
        my := player.y;
        if(gameMode = COMBAT) {
            combatRoundInfo := combat.round[combat.roundIndex];
            if(combatRoundInfo.type = "pc") {
                mx := player.x;
                my := player.y;
            } else {
                mx := combatRoundInfo.monster.pos[0];
                my := combatRoundInfo.monster.pos[1];
            }
        }
        array_foreach(map.monster, (i, m) => { m.visible := false; });
        drawViewRadius(mx, my, LIGHT_RADIUS * 2);
        startCombat();
    }    
}

def initLight() {
    mx := player.x - LIGHT_RADIUS; 
    while(mx <= player.x + LIGHT_RADIUS) {
        my := player.y - LIGHT_RADIUS;
        while(my <= player.y + LIGHT_RADIUS) {
            block := getBlock(mx, my);
            if(player.x = mx && player.y = my) {
                block["light"] := 1;
            } else {
                block["light"] := -1;
            }
            my := my + 1;
        }
        mx := mx + 1;
    }
    findLight(player.x, player.y);
}

def findLight(mx, my) {
    dx := mx - player.x;
    dy := my - player.y;
    if(abs(dx) <= LIGHT_RADIUS && abs(dy) <= LIGHT_RADIUS) {
        block := getBlock(mx, my);
        block.light := 1;
        if(blocks[block.block].light = false) {
            if(getBlock(mx - 1, my).light = -1) {
                findLight(mx - 1, my);
            }
            if(getBlock(mx + 1, my).light = -1) {
                findLight(mx + 1, my);
            }
            if(getBlock(mx, my - 1).light = -1) {
                findLight(mx, my - 1);
            }
            if(getBlock(mx, my + 1).light = -1) {
                findLight(mx, my + 1);
            }
            if(getBlock(mx - 1, my - 1).light = -1) {
                findLight(mx - 1, my - 1);
            }
            if(getBlock(mx + 1, my - 1).light = -1) {
                findLight(mx + 1, my - 1);
            }
            if(getBlock(mx - 1, my + 1).light = -1) {
                findLight(mx - 1, my + 1);
            }
            if(getBlock(mx + 1, my + 1).light = -1) {
                findLight(mx + 1, my + 1);
            }

        }
    }
}

def gameIsBlockVisible(mx, my) {
    block := getBlock(mx, my);
    return block["light"] = 1;
}

def gameDrawViewAt(x, y, mx, my, onScreen) {
    if(onScreen) {
        if(gameMode = COMBAT) {
            # draw the other party members
            array_foreach(player.party, (i, p) => {
                if(mx = p.pos[0] && my = p.pos[1]) {
                    if(p.hp > 0) {
                        drawImage(x, y, p.image, 0);
                    } else {
                        drawImage(x, y, img["bones"], 0);
                    }
                    if(combat.playerControl && i = player.partyIndex) {
                        drawRect(x, y, x + TILE_W - 1, y + TILE_H - 1, COLOR_YELLOW);
                    }
                }
            });
        } else {
            # draw the player only
            if(mx = player.x && my = player.y) {
                drawImage(x, y, player.party[player.partyIndex].image, 0);
            }
        }
        array_foreach(map.npc, (i, e) => {
            if(e.pos[0] = mx && e.pos[1] = my) {
                drawImage(x, y, e.image, 0);
            }
        });
    }
    array_foreach(map.monster, (i, e) => {
        if(e.pos[0] = mx && e.pos[1] = my) {
            if(e.hp > 0) {
                e.visible := true;
            }
            if(onScreen) {
                if(e.hp > 0) {
                    drawImage(x, y, e.image, 0);
                } else {
                    drawImage(x, y, img["blood"], 0);
                }
                if(gameMode = COMBAT && combat.playerControl = false) {
                    if(combat.round[combat.roundIndex].monster.id = e.id) {
                        drawRect(x, y, x + TILE_W - 1, y + TILE_H - 1, COLOR_YELLOW);
                    }
                }
            }
        }
    });
}

def moveNpcs() {
    array_foreach(map.npc, (i, e) => {
        if(random() > 0.5) {
            dx := choose([ 1, -1 ]);
            dy := choose([ 1, -1 ]);
            e.pos[0] := e.pos[0] + dx;
            e.pos[1] := e.pos[1] + dy;
            block := blocks[getBlock(e.pos[0], e.pos[1]).block];
            if(block.blocking || 
                abs(e.pos[0] - e.start[0]) > 5 || 
                abs(e.pos[1] - e.start[1]) > 5 || 
                (e.pos[0] = player.x && e.pos[1] = player.y)
            ) {
                e.pos[0] := e.pos[0] - dx;
                e.pos[1] := e.pos[1] - dy;
            }
        }
    });
}

def getMapStartPos(nextMapName) {
    m := links[nextMapName];
    k := keys(m);
    i := 0;
    while(i < len(k)) {
        if(m[k[i]] = mapName) {
            pos := split(k[i], ",");
            return [int(pos[0]), int(pos[1])];
        }
        i := i + 1;
    }
    # error
    return null;
}

def applyGameBlocks(newMapName) {
    # apply map block changes (doors, secrets, etc)
    m := player.blocks[newMapName];
    if(m != null) {
        k := keys(m);
        i := 0;
        while(i < len(k)) {
            pos := split(k[i], ",");
            setBlock(int(pos[0]), int(pos[1]), m[k[i]], 0);
            i := i + 1;
        }
    }
}

def gameEnterMap() {
    key := "" + player.x + "," + player.y;
    if(links[mapName] != null) {
        s := links[mapName][key];
        if(s != null) {
            ss := split(s, ",");
            if(len(ss) > 1) {
                gameLoadMap(ss[0]);
                player.map := ss[0];
                player.x := int(ss[1]);
                player.y := int(ss[2]);
            } else {
                pos := getMapStartPos(s);
                gameLoadMap(s);
                player.x := pos[0];
                player.y := pos[1];
                player.map := s;
            }            
            saveGame();
            if(events[mapName] != null) {
                events[mapName].onEnter();
            } else {
                gameMessage("Enter another area.", COLOR_MID_GRAY);
            }
        }
    }
}

def aroundPlayer(fx) {
    dx := -1;
    while(dx <= 1) {
        dy := -1;
        while(dy <= 1) {
            res := fx(player.x + dx, player.y + dy);
            if(res != null) {
                return res;
            }
            dy := dy + 1;
        }
        dx := dx + 1;
    }
    return null;
}

def gameUseDoor() {
    aroundPlayer((x, y) => {
        block := blocks[getBlock(x, y).block];
        if(block["nextState"] != null) {
            index := getBlockIndexByName(block.nextState);
            setBlock(x, y, index, 0);
            setGameBlock(x, y, index);
            gameMessage("Use a door.", COLOR_MID_GRAY);
            return 1;
        } else {
            return null;
        }
    });
}

def gameSearch() {
    aroundPlayer((x, y) => {
        space := getBlockIndexByName("space");
        block := getBlock(x, y).block;
        if(map.secrets["" + x + "," + y] = 1 && block != space) {
            setBlock(x, y, space, 0);
            setGameBlock(x, y, space);
            gameMessage("Found a secret door!", COLOR_MID_GRAY);
            return 1;
        } else {
            return null;
        }
    });
}

def gameConvo() {
    aroundPlayer((x, y) => {
        n := array_find(map.npc, e => e.pos[0] = x && e.pos[1] = y);
        if(n != null && events[mapName]["onConvo"] != null) {
            convo := events[mapName].onConvo(n);
            if(convo != null) {
                startConvo(n, convo);
                return 1;
            }
        }
        return null;
    });
}

def startConvo(theNpc, theConvoMap) {
    gameMode := CONVO;
    convo.npc := theNpc;
    convo.map := theConvoMap;
    convo.key := "";

    clearGameMessages();
    gameMessageLong(true);
    gameMessage("Talking to " + theNpc.name, COLOR_GREEN);
    showConvoText();
}

def showConvoText() {
    result := {
        "words": "",
        "answers": [],
    };
    text := null;
    tradeMode := null;
    if(convo.key = "_trade_") {
        text := "Do you want to $sell|_sell_ or $buy|_buy_?";
        result.answers[0] := [ "Bye", "bye" ];
    }
    if(convo.key = "_buy_") {
        tradeMode := convo.key;
        text := "Choose from my wares.";
    }
    if(convo.key = "_sell_") {
        tradeMode := convo.key;
        text := "What do you want to sell?";
    }
    if(text = null) {
        text := convo.map[convo.key];
        result.answers[0] := [ "Bye", "bye" ];
    }
    if(typeof(text) = "function") {
        text := text();
    }
    array_foreach(split(text, " "), (i, s) => {
        if(len(result.words) > 0) {
            result.words := result.words + " ";
        }
        if(substr(s, 0, 1) = "$") {
            # remove trailing punctuation
            w := split(s, "[.,!?:;]");
            ss := split(substr(w[0], 1), "\\|");
            if(len(ss) > 1) {
                result.answers[len(result.answers)] := [ ss[0], ss[1] ];
            } else {
                result.answers[len(result.answers)] := [ ss[0], ss[0] ];
            }
            result.words := result.words + "_15_" + ss[0];

            # add the punctuation
            result.words := result.words + substr(s, len(w[0]));
        } else {
            result.words := result.words + s;
        }
    });
    gameMessage(" ", COLOR_MID_GRAY);
    gameMessage(result.words, COLOR_MID_GRAY);
    array_foreach(result.answers, (i, s) => gameMessage("" + (i + 1) + ": " + s[0], COLOR_WHITE));
    convo.answers := result.answers;
}

def setGameState(name, value) {
    player.gameState[name] := value;
    saveGame();
}

def getGameState(name) {
    return player.gameState[name];
}

def setGameBlock(x, y, index) {
    if(player.blocks[player.map] = null) {
        player.blocks[player.map] := {};
    }
    player.blocks[player.map]["" + x + "," + y] := index;
    saveGame();
}

def saveGame() {
    array_foreach(map.monster, (i, m) => {
        player.monster[mapName][m.id] := {
            "hp": m.hp,
            "pos": m.pos,
        };
    });
    save("savegame.dat", player);
}

def showGameHelp() {
    clearGameMessages();
    gameMessageLong(true);
    gameMessage("_1_Arrows: movement", COLOR_MID_GRAY);
    gameMessage("_1_H: help", COLOR_MID_GRAY);
    gameMessage("_1_S: speak", COLOR_MID_GRAY);
    gameMessage("_1_Space: search/use door", COLOR_MID_GRAY);
    gameMessage("_1_Enter: use stairs/gate", COLOR_MID_GRAY);
    gameMessage("_1_Numbers: option in conversation or trade", COLOR_MID_GRAY);
    gameMessageLong(false);
}

def gameInput() {
    if(isKeyDown(KeyH)) {
        while(anyKeyDown()) {}
        showGameHelp();
    }

    if(moreText && isKeyDown(KeySpace)) {
        while(anyKeyDown()) {}
        pageGameMessages();
    }
    if(gameMode = MOVE || (gameMode = COMBAT && combat.playerControl)) {
        apUsed := 0;
        ox := player.x;
        oy := player.y;
        if(isKeyDown(KeyEnter)) {
            while(isKeyDown(KeySpace)) {
            }
            gameEnterMap();
        }
        if(isKeyDown(KeyT)) {
            while(isKeyDown(KeySpace)) {
            }
            gameConvo();
        }
        if(isKeyDown(KeySpace)) {
            while(isKeyDown(KeySpace)) {
            }
            gameUseDoor();
            gameSearch();
            apUsed := apUsed + 1;
        }
        if(isKeyDown(KeyUp)) {
            player.y := player.y - 1;
        }
        if(isKeyDown(KeyDown)) {
            player.y := player.y + 1;
        }
        if(isKeyDown(KeyLeft)) {
            player.x := player.x - 1;
        }
        if(isKeyDown(KeyRight)) {
            player.x := player.x + 1;
        }        

        blocked := player.x < 0 || player.y < 0 || player.x >= map.width || player.y >= map.height;
        if(blocked = false) {
            m := array_find(map.monster, e => e.pos[0] = player.x && e.pos[1] = player.y && e.hp > 0);
            blocked := m != null;
            if(m != null && gameMode = COMBAT) {
                apUsed := apUsed + playerAttacks(m);
            }
        }
        if(blocked = false) {
            block := blocks[getBlock(player.x, player.y).block];
            blocked := block.blocking;
        }
        if(blocked = false && gameMode = COMBAT) {
            # if old pos is not on another player
            if(array_find(player.party, e => e.pos[0] = ox && e.pos[1] = oy && e.hp > 0 && e.index != player.partyIndex) = null) {
                # don't allow stepping on another live player
                blocked := array_find(player.party, e => e.pos[0] = player.x && e.pos[1] = player.y && e.hp > 0 && e.index != player.partyIndex) != null;
            }
        }
        if(blocked) {
            player.x := ox;
            player.y := oy;
        } else {
            # if stepping on an npc, swap places
            n := array_find(map.npc, e => e.pos[0] = player.x && e.pos[1] = player.y);
            if(n != null) {
                n.pos[0] := ox;
                n.pos[1] := oy;
            }

            if(gameMode = COMBAT) {
                # trace("SAVING POS of " + player.partyIndex);
                player.party[player.partyIndex].pos[0] := player.x;
                player.party[player.partyIndex].pos[1] := player.y;
                apUsed := apUsed + 1;
            }
        }

        # do this last, as it can switch players
        if(gameMode = COMBAT && apUsed > 0) {
            combatTurnStep(apUsed);
        }
    }

    if(gameMode = CONVO) {
        index := null;
        if(isKeyDown(Key1) || isKeyDown(KeyEscape)) {
            while(anyKeyDown()) {}
            index := 0;
        }
        if(isKeyDown(Key2)) {
            while(anyKeyDown()) {}
            index := 1;
        }
        if(isKeyDown(Key3)) {
            while(anyKeyDown()) {}
            index := 2;
        }
        if(isKeyDown(Key4)) {
            while(anyKeyDown()) {}
            index := 3;
        }
        if(isKeyDown(Key5)) {
            while(anyKeyDown()) {}
            index := 4;
        }
        if(isKeyDown(Key6)) {
            while(anyKeyDown()) {}
            index := 5;
        }
        if(index != null) {
            if(index = 0) {
                gameMode := MOVE;
                tradeMode := null;
                gameMessage("Bye.", COLOR_MID_GRAY);
                gameMessageLong(false);
            } else {
                if(tradeMode = "_buy_") {
                    buyItem(index - 1);
                }
                if(tradeMode = "_sell_") {
                    sellItem(index - 1);
                }
                if(tradeMode = null) {
                    if(len(convo.answers) > index) {
                        convo.key := convo.answers[index][1];
                        clearGameMessages();
                        showConvoText();
                    }
                }
            }
        }
    }
}

def buyItem(index) {
    inv := player.traders[mapName][convo.npc.name];
    if(index < len(inv)) {
        item := ITEMS_BY_NAME[inv[index].name];
        if(player.coins >= item.price) {
            gameMessage("You bought " + item.name + " for $" + item.price + ".", COLOR_GREEN);
            player.coins := player.coins - item.price;
            player.inventory[len(player.inventory)] := itemInstance(item);
            del inv[index];
            saveGame();
        } else {
            gameMessage("You don't have enough money to buy that.", COLOR_RED);
        }
    } else {
        gameMessage("Invalid choice.", COLOR_MID_GRAY);
    }
}

def sellItem(index) {
    # todo: only show items of certain type
    if(index < len(player.inventory)) {
        item := itemInstance(player.inventory[index].name);
        gameMessage("You sold " + item.name + " for $" + item.sellPrice + ".", COLOR_GREEN);
        player.coins := player.coins + item.sellPrice;
        del player.inventory[index];
        saveGame();
    } else {
        gameMessage("Invalid choice.", COLOR_MID_GRAY);
    }
}
