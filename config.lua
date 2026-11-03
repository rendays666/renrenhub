local REN = ((getgenv and getgenv()) or _G).REN

REN.CONFIG = {
    Version = "v4.2",
    FirebaseURL = "https://renrenscript-default-rtdb.asia-southeast1.firebasedatabase.app",

    TrackCooldown    = 90,
    SessionTimeout   = 200,
    TrackDebounce    = 60,
    AutoExecDebounce = 300,
    FullPushInterval = 300,
    CleanupCooldown  = 3600,
    ExecutesTTL      = 7 * 86400,

    MusicVolume = 0.5,
}

REN.Playlist = {
    { name = "Low Cortisol",  id = "rbxassetid://110919391228823" },
    { name = "bazooka",       id = "rbxassetid://121252909004354" },
    { name = "TerraAway",     id = "rbxassetid://82746224492420" },
    { name = "Your Old Life", id = "rbxassetid://91785810573969" },
}

REN.Maps = {
    [8735521924] = {
        id = "centaura",
        name = "Centaura",
        scriptUrl = "https://raw.githubusercontent.com/rendays666/renrenscript/refs/heads/main/centaura.lua",
        description = "Auto-win Centaura",
        imageUrl = "",
    },
    [113273588963037] = {
        id = "oneup",
        name = "+1 Upgrade Per Kill",
        scriptUrl = "https://raw.githubusercontent.com/rendays666/renrenscript/refs/heads/main/renrenhub%20%2B1UPGRADE%20per%20kill.lua",
        description = "Best script for 1UP Kill",
        imageUrl = "",
    },
}

REN.UniversalScripts = {
    {
        id = "universal_1",
        name = "Universal Script",
        scriptUrl = "https://pastebin.com/raw/Vd2ZYevk",
        description = "Works on any map (fallback)",
        imageUrl = "",
    },
}

print("[REN] ✅ Config ready")
