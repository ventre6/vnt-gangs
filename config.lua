Config = {}

Config.gangs = {
    ["cartel"] = {
        stash = {
            name = 'Cartel Stash',
            coords = vector3(-1485.56, -160.01, 48.83),
        },
        market = {
            hasMarket = 0,
            name = 'Cartel Market',
            inventory = {
                { name = 'weapon_pistol', price = 10 },
                { name = 'water', price = 10 },
            },
        },
        tacir = {
            hasTacir = 0,
            name = "Cartel Tacir",
            inventory = {
                { name = 'weed_brick', price = 100 },
            },
        },
        grades = {
            { name = 'Enforcer', level = 3 },
            { name = 'Shot Caller', level = 2 },
            { name = 'Boss', level = 1 },
        }
    },
    ["ballas"] = {
        stash = {
            name = 'Ballas Stash',
            coords = vector3(-1470.85, -177.88, 48.82),
        },
        market = {
            hasMarket = 0,
            name = 'Ballas Market',
            inventory = {
                { name = 'weapon_pistol_mk2', price = 10 },
                { name = 'ammo-9', price = 10 },
            },
        },
        tacir = {
            hasTacir = 0,
            name = "Ballas Tacir",
            inventory = {
                { name = 'weed_brick', price = 100 },
            },
        },
        grades = {
            { name = 'Enforcer', level = 3 },
            { name = 'Shot Caller', level = 2 },
            { name = 'Boss', level = 1 },
        }
    },
    ["families"] = {
        stash = {
            name = 'Famillies Stash',
            coords = vector3(-136.91, -1609.84, 35.03),
        },
        market = {
            hasMarket = 0,
            name = 'Famillies Market',
            inventory = {
                { name = 'burger', price = 10 },
                { name = 'water', price = 10 },
            },
        },
        tacir = {
            hasTacir = 0,
            name = "Famillies Tacir",
            inventory = {
                { name = 'weed_brick', price = 100 },
            },
        },
        grades = {
            { name = 'Enforcer', level = 3 },
            { name = 'Shot Caller', level = 2 },
            { name = 'Boss', level = 1 },
        }
    },
}
