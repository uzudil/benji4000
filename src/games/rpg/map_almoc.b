const events_almoc = {
    "onEnter": self => {
        if(player.gameState["almoc"] = null) {
            setGameState("almoc", true);
            gameMessage("You arrive in Almoc. You hear the noise of the village market.", COLOR_LIGHT_BLUE);
        } else {
            gameMessage("Arrived in the village Almoc", COLOR_LIGHT_BLUE);
        }
    },
    "onNpcInit": self => {
        return [
            { "name": "Arnel", "block": "man1", "pos": [10, 12] },
            { "name": "Snael", "block": "man2", "pos": [23, 10] },
            { "name": "Ragh", "block": "man3", "pos": [15, 18] },
            { "name": "Malde", "block": "woman1", "pos": [17, 16] },
            { "name": "Vinkh", "block": "woman2", "pos": [22, 21] },
        ];
    },
};
