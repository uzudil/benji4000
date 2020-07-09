const MESSAGES_WIDTH = 16;
const MESSAGES_SIZE = 10;

def splitGameMessage(message) {
    words := split(message, " ");
    t := 0;
    lines := [];
    line := "";
    while(t < len(words)) {
        if(len(words[t]) >= MESSAGES_WIDTH) {
            words[t] := substr(words[t], 0, MESSAGES_WIDTH - 1);
        }
        new := "";
        if(len(line) > 0) {
            new := new + " ";
        }
        new := new + words[t];
        if(len(line + new) < MESSAGES_WIDTH) {
            line := line + new;
            t := t + 1;
        } else {
            lines[len(lines)] := line;
            line := "";
        }
    }
    if(len(line) > 0) {
        lines[len(lines)] := line;
    }
    return lines;
}

def pageGameMessages() {
    i := 0;
    while(i < MESSAGES_SIZE - 1 && len(player.messages) > MESSAGES_SIZE) {
        del player.messages[0];
        i := i + 1;
    }
    moreText := len(player.messages) > MESSAGES_SIZE;
}

def gameMessage(message, color) {
    lines := splitGameMessage(message);
    t := 0;
    while(t < len(lines)) {
        player.messages[len(player.messages)] := [lines[t], color];
        t := t + 1;
    }
    moreText := gameMode = CONVO && len(player.messages) > MESSAGES_SIZE;
    if(gameMode = CONVO = false) {
        while(len(player.messages) > MESSAGES_SIZE) {
            del player.messages[0];
        }   
    }
}

def drawGameMessages(x, y) {
    ty := y;
    i := len(player.messages) - 1;
    if(moreText) {
        i := MESSAGES_SIZE - 2;
        drawColoredText(x + 2, ty + 2, COLOR_YELLOW, COLOR_BLACK, "<<Press SPACE>>");
        ty := ty - 10;
    }
    while(i >= 0) {
        drawColoredText(x + 2, ty + 2, player.messages[i][1], COLOR_BLACK, player.messages[i][0]);
        ty := ty - 10;
        i := i - 1;
    }
}

def clearGameMessages() {
    player.messages := [];
    moreText := false;
}
