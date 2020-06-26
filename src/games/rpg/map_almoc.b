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
            { "name": "Ragh", "block": "man3", "pos": [10, 22] },
            { "name": "Malde", "block": "woman1", "pos": [17, 16] },
            { "name": "Vinkh", "block": "woman2", "pos": [22, 22] },
        ];
    },
    "onConvo": (self, n) => {
        if(n.name = "Arnel") {
            return {
                "": "Can I $help you stranger?",
                "help": "You are in Almoc. We have a $supplies store, an $inn and an $armorer.",
                "supplies": "Snael's wares are southeast of here. Anything $else|help?",
                "inn": "Aye, the Inn of the Rose to the east. Anything $else|help?",
                "armorer": "Tools for violence can be found at Ragh's, to the south. Anything $else|help?",
            };
        }
        if(n.name = "Snael") {
            return {
                "": "I $sell|_trade_ food and draughts. Prices are reasonable and quite final.",
            };
        }
        if(n.name = "Vinkh") {
            return {
                "": "Need $supplies|_trade_, stranger?",
            };
        }
        if(n.name = "Malde") {
            return {
                "": "So the $rumors are true...",
                "rumors": "You look eerily similar to $Zathos|undead and $Xaram|undead before him...",
                "undead": "Names from the past. They're of no $importance.",
                "importance": "La-lee-la-la! I sure am $hungry!",
                "hungry": "We all hunger for something, $amirite?!",
                "amirite": "I'll tell you a $rumor|rumors for a $morsel.",
                "morsel": () => {
                    food := array_find_index(player.inventory, item => item.type = OBJECT_FOOD);
                    if(food > -1) {
                        gameMessage("You give Malde " + player.inventory[food].name + ".", COLOR_GREEN);
                        del player.inventory[food];
                        return "That was delicious. Now I can tell you my $secret!";
                    } else {
                        return "I'm so hungry! Feed me and I will tell you the $rumors I heard.";
                    }
                },
                "secret": "The stories say, the dead come back to $life. It has happened before, right here in Almoc!",
                "life": "Aye, just like $you, they wander up from the crypts.",
                "you": "I don't know why it happened to you. You should ask a $sage about it.",
                "sage": "They live in remote places, so I'm told. Want to hear your $secret again?",
            };
        }
        if(n.name = "Ragh") {
            return {
                "": "Looking to $trade|_trade_ weapons or armor?",
            };
        }
        return null;
    },
    "onTrade": (self, n) => {
        if(n.name = "Snael") {
            return [ OBJECT_FOOD, OBJECT_DRINK ];
        }
        if(n.name = "Ragh") {
            return [ OBJECT_ARMOR, OBJECT_WEAPON ];
        }
        if(n.name = "Vinkh") {
            return [ OBJECT_SUPPLIES ];
        }
        return null;
    },
};
