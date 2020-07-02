const events_bonefell = {
    "onEnter": self => {
        gameMessage("Dungeon Bonefell", COLOR_LIGHT_BLUE);
    },
    "onMonsterKilled": (self, monster) => {
        if(monster.monsterTemplate.block = "rat") {
            c := getGameState("almoc_rats");
            if(c = null) {
                c := 0;
            }
            setGameState("almoc_rats", c + 1);
            trace("almoc rats killed=" + getGameState("almoc_rats"));
        }
    },
};
