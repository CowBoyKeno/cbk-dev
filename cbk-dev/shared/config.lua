Config = {}

Config.MenuTitle = 'CBK Dev Menu'
Config.KeybindCommand = 'cbkdevmenu'
Config.KeybindDescription = 'Open the CBK dev menu'
Config.DefaultKey = 'F1'

Config.OpenStatusRefreshMs = 200
Config.NoclipSpeed = 1.5
Config.NoclipFastMultiplier = 3.5
Config.NoclipSlowMultiplier = 0.35

Config.WeatherPresets = {
    { label = 'Clear', value = 'CLEAR' },
    { label = 'Extra Sunny', value = 'EXTRASUNNY' },
    { label = 'Clouds', value = 'CLOUDS' },
    { label = 'Overcast', value = 'OVERCAST' },
    { label = 'Rain', value = 'RAIN' },
    { label = 'Thunder', value = 'THUNDER' },
    { label = 'Foggy', value = 'FOGGY' },
    { label = 'Smog', value = 'SMOG' },
    { label = 'Xmas', value = 'XMAS' },
    { label = 'Halloween', value = 'HALLOWEEN' },
}

Config.TimePresets = {
    { label = 'Morning', hour = 8, minute = 0 },
    { label = 'Noon', hour = 12, minute = 0 },
    { label = 'Evening', hour = 18, minute = 0 },
    { label = 'Midnight', hour = 0, minute = 0 },
}

Config.Weapons = {
    'WEAPON_KNIFE',
    'WEAPON_NIGHTSTICK',
    'WEAPON_HAMMER',
    'WEAPON_BAT',
    'WEAPON_CROWBAR',
    'WEAPON_PISTOL',
    'WEAPON_COMBATPISTOL',
    'WEAPON_APPISTOL',
    'WEAPON_PISTOL50',
    'WEAPON_SNSPISTOL',
    'WEAPON_HEAVYPISTOL',
    'WEAPON_VINTAGEPISTOL',
    'WEAPON_STUNGUN',
    'WEAPON_FLAREGUN',
    'WEAPON_MARKSMANPISTOL',
    'WEAPON_REVOLVER',
    'WEAPON_DOUBLEACTION',
    'WEAPON_MICROSMG',
    'WEAPON_SMG',
    'WEAPON_ASSAULTSMG',
    'WEAPON_COMBATPDW',
    'WEAPON_MACHINEPISTOL',
    'WEAPON_MINISMG',
    'WEAPON_PUMPSHOTGUN',
    'WEAPON_SAWNOFFSHOTGUN',
    'WEAPON_BULLPUPSHOTGUN',
    'WEAPON_ASSAULTSHOTGUN',
    'WEAPON_MUSKET',
    'WEAPON_HEAVYSHOTGUN',
    'WEAPON_DBSHOTGUN',
    'WEAPON_AUTOSHOTGUN',
    'WEAPON_ASSAULTRIFLE',
    'WEAPON_CARBINERIFLE',
    'WEAPON_ADVANCEDRIFLE',
    'WEAPON_SPECIALCARBINE',
    'WEAPON_BULLPUPRIFLE',
    'WEAPON_COMPACTRIFLE',
    'WEAPON_MG',
    'WEAPON_COMBATMG',
    'WEAPON_GUSENBERG',
    'WEAPON_SNIPERRIFLE',
    'WEAPON_HEAVYSNIPER',
    'WEAPON_MARKSMANRIFLE',
    'WEAPON_RPG',
    'WEAPON_GRENADELAUNCHER',
    'WEAPON_MINIGUN',
    'WEAPON_FIREWORK',
    'WEAPON_RAILGUN',
    'WEAPON_HOMINGLAUNCHER',
    'WEAPON_COMPACTLAUNCHER',
    'WEAPON_GRENADE',
    'WEAPON_STICKYBOMB',
    'WEAPON_PROXMINE',
    'WEAPON_BZGAS',
    'WEAPON_MOLOTOV',
    'WEAPON_FIREEXTINGUISHER',
    'WEAPON_PETROLCAN',
    'WEAPON_PARACHUTE'
}

Config.AmmoByWeapon = {
    default = 9999,
    WEAPON_RPG = 50,
    WEAPON_GRENADELAUNCHER = 50,
    WEAPON_MINIGUN = 9999,
    WEAPON_FIREWORK = 50,
    WEAPON_RAILGUN = 250,
    WEAPON_HOMINGLAUNCHER = 50,
    WEAPON_COMPACTLAUNCHER = 50,
    WEAPON_GRENADE = 50,
    WEAPON_STICKYBOMB = 50,
    WEAPON_PROXMINE = 50,
    WEAPON_BZGAS = 50,
    WEAPON_MOLOTOV = 50,
    WEAPON_PETROLCAN = 4500,
    WEAPON_PARACHUTE = 1
}

Config.VehicleModTypeLabels = {
    [0] = 'Spoiler',
    [1] = 'Front Bumper',
    [2] = 'Rear Bumper',
    [3] = 'Side Skirt',
    [4] = 'Exhaust',
    [5] = 'Frame',
    [6] = 'Grille',
    [7] = 'Hood',
    [8] = 'Fender',
    [9] = 'Right Fender',
    [10] = 'Roof',
    [11] = 'Engine',
    [12] = 'Brakes',
    [13] = 'Transmission',
    [14] = 'Horn',
    [15] = 'Suspension',
    [16] = 'Armor',
    [17] = 'Turbo',
    [18] = 'Xenon Lights',
    [19] = 'Front Wheels',
    [20] = 'Rear Wheels',
    [21] = 'Plate Holder',
    [22] = 'Window Tint / Unknown',
    [23] = 'Livery',
    [24] = 'Roof Accessories',
    [25] = 'Engine Block',
    [26] = 'Air Filter',
    [27] = 'Struts',
    [28] = 'Arch Cover',
    [29] = 'Aerials',
    [30] = 'Trim Design',
    [31] = 'Ornaments',
    [32] = 'Dashboard',
    [33] = 'Dial Design',
    [34] = 'Door Speakers',
    [35] = 'Seats',
    [36] = 'Steering Wheel',
    [37] = 'Shifter Levers',
    [38] = 'Plaques',
    [39] = 'Speakers',
    [40] = 'Trunk',
    [41] = 'Hydraulics',
    [42] = 'Engine Block 2',
    [43] = 'Air Filter 2',
    [44] = 'Struts 2',
    [45] = 'Arch Cover 2',
    [46] = 'Aerials 2',
    [47] = 'Trim Design 2',
    [48] = 'Ornaments 2',
    [49] = 'Dashboard 2'
}

Config.VehicleWindowTintLabels = {
    [0] = 'Neutral',
    [1] = 'Green',
    [2] = 'Limo',
    [3] = 'Dark Smoke',
    [4] = 'Pure Black',
    [5] = 'Unknown'
}

Config.VehiclePlateIndexLabels = {
    [0] = 'Blue on White 1',
    [1] = 'Yellow on Blue',
    [2] = 'Yellow on Black',
    [3] = 'Blue on White 2',
    [4] = 'Yellow on Blue 2'
}
