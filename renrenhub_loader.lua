--[[
  RENRENHUB v4.2 — LOADER (MAIN ENTRY)
  Ini file yang kamu execute. Fungsinya:
  1. Setup config, STATE, services, HTTP helpers, toast, gameName
  2. Fetch 3 module via loadstring (database, music, scriptloader)
  3. Boot semua: music, session, heartbeat, auto-exec
  Semua data di-share via _G.REN
]]

print("[REN] ════════ v4.2 START ════════")

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  PERSISTENT STATE                                                  ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local env = (getgenv and getgenv()) or _G
env.REN = env.REN or {}
local STATE = env.REN

if not STATE.initialized then
    STATE.initialized    = true
    STATE.trackCache     = {}
    STATE.lastAutoExec   = {}
    STATE.lastFullPush   = 0
    STATE.lastHeartbeat  = 0
    STATE.lastCleanup    = 0
    STATE.cleanupRunning = false
    STATE.heartbeatActive= false
    STATE.lastReinject   = 0
    STATE.sessionDeleted = false
end

if STATE.lastReinject > 0 and (os.time() - STATE.lastReinject) < 10 then
    print("[REN] ⏭️ Skip reinject (< 10s)")
    return
end
STATE.lastReinject = os.time()
STATE.sessionDeleted = false

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  🎛️ CONFIG                                                        ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local CONFIG = {
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

-- 🎵 PLAYLIST — tambah lagu di sini
local Playlist = {
    { name = "Low Cortisol",  id = "rbxassetid://110919391228823" },
    { name = "bazooka",       id = "rbxassetid://121252909004354" },
    { name = "TerraAway",     id = "rbxassetid://82746224492420" },
    { name = "Your Old Life", id = "rbxassetid://91785810573969" },
}

-- 🗺️ MAPS — tambah script di sini
local Maps = {
    [8735521924] = {
        id = "centaura", name = "Centaura",
        scriptUrl = "https://raw.githubusercontent.com/rendays666/renrenscript/refs/heads/main/centaura.lua",
        description = "Auto-win Centaura", imageUrl = "",
    },
    [113273588963037] = {
        id = "oneup", name = "+1 Upgrade Per Kill",
        scriptUrl = "https://pastebin.com/raw/Vd2ZYevk",
        description = "Best script for 1UP Kill", imageUrl = "",
    },
}

local UniversalScripts = {
    { id = "universal_1", name = "Universal Script",
      scriptUrl = "https://pastebin.com/raw/Vd2ZYevk",
      description = "Works on any map (fallback)", imageUrl = "" },
}

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  SERVICES                                                          ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
if not player then return end
local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 10)
if not pg then return end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  HTTP HELPERS                                                      ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local function httpReq(url, method, body)
    local p = {Url=url, Method=method, Headers={["Content-Type"]="application/json"}, Body=body}
    local ok, r = pcall(function() return syn.request(p) end)
    if ok and r then return r end
    ok, r = pcall(function() return http_request(p) end)
    if ok and r then return r end
    ok, r = pcall(function() return request(p) end)
    if ok and r then return r end
    return nil
end

local function httpGet(url)
    local ok, r = pcall(function() return game:HttpGet(url, true) end)
    if ok and r and r ~= "" then return r end
    if syn and syn.request then
        local x = pcall(function() return syn.request({Url=url, Method="GET"}) end)
        if x and x.Body then return x.Body end
    end
    if http_request then
        local x = pcall(function() return http_request({Url=url, Method="GET"}) end)
        if x and x.Body then return x.Body end
    end
    if request then
        local x = pcall(function() return request({Url=url, Method="GET"}) end)
        if x and x.Body then return x.Body end
    end
    return nil
end

local function firebaseReq(method, path, data)
    local body = data and HttpService:JSONEncode(data) or nil
    return httpReq(CONFIG.FirebaseURL .. path, method, body)
end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  GAME NAME                                                         ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local cachedGameName = nil
local function getGameName()
    if cachedGameName then return cachedGameName end
    local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    if ok and info and info.Name and info.Name ~= "" then
        cachedGameName = info.Name; return cachedGameName
    end
    local ok2, res = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games?universeIds=" .. tostring(game.GameId))
    end)
    if ok2 and res then
        local ok3, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok3 and data and data.data and data.data[1] and data.data[1].name then
            cachedGameName = data.data[1].name; return cachedGameName
        end
    end
    cachedGameName = "Game #" .. tostring(game.PlaceId)
    return cachedGameName
end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  TOAST                                                             ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local function toast(title, msg, duration)
    local gui = pg:FindFirstChild("REN_Toast")
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "REN_Toast"; gui.ResetOnSpawn = false
        gui.DisplayOrder = 999; gui.Parent = pg
    end
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 340, 0, 72)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.Position = UDim2.new(0.5, 0, 0, -90)
    frame.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
    frame.BorderSizePixel = 0; frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local s = Instance.new("UIStroke", frame)
    s.Color = Color3.fromRGB(0, 220, 160); s.Thickness = 2
    local t = Instance.new("TextLabel", frame)
    t.Size = UDim2.new(1, -24, 0, 22); t.Position = UDim2.new(0, 12, 0, 8)
    t.BackgroundTransparency = 1; t.Text = title
    t.TextColor3 = Color3.fromRGB(0, 220, 160)
    t.Font = Enum.Font.GothamBold; t.TextSize = 14
    t.TextXAlignment = Enum.TextXAlignment.Left
    local m = Instance.new("TextLabel", frame)
    m.Size = UDim2.new(1, -24, 0, 34); m.Position = UDim2.new(0, 12, 0, 30)
    m.BackgroundTransparency = 1; m.Text = msg
    m.TextColor3 = Color3.fromRGB(220, 220, 235)
    m.Font = Enum.Font.Gotham; m.TextSize = 12
    m.TextXAlignment = Enum.TextXAlignment.Left
    m.TextWrapped = true
    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
        Position = UDim2.new(0.5, 0, 0, 20)
    }):Play()
    task.delay(duration or 3, function()
        if not frame.Parent then return end
        TweenService:Create(frame, TweenInfo.new(0.3), {
            Position = UDim2.new(0.5, 0, 0, -90)
        }):Play()
        task.delay(0.4, function() if frame.Parent then frame:Destroy() end end)
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  EXPORT KE SHARED TABLE (_G.REN)                                   ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local REN = env.REN
REN.CONFIG = CONFIG
REN.Playlist = Playlist
REN.Maps = Maps
REN.UniversalScripts = UniversalScripts
REN.Players = Players
REN.HttpService = HttpService
REN.SoundService = SoundService
REN.TweenService = TweenService
REN.UIS = UIS
REN.MarketplaceService = MarketplaceService
REN.player = player
REN.pg = pg
REN.httpReq = httpReq
REN.httpGet = httpGet
REN.firebaseReq = firebaseReq
REN.getGameName = getGameName
REN.toast = toast
print("[REN] Core shared ready")

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  ⚠️ GANTI URL DI SINI — sesuai tempat kamu upload module           ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local MODULES = {
    Database     = "https://raw.githubusercontent.com/rendays666/renrenhub/refs/heads/main/renrenhub_database.lua",
    Music        = "https://raw.githubusercontent.com/rendays666/renrenhub/refs/heads/main/renrenhub_music.lua",
    ScriptLoader = "https://raw.githubusercontent.com/rendays666/renrenhub/refs/heads/main/renrenhub_scriptloader.lua",
}

local function fetchModule(name, url)
    print("[REN] Fetching module:", name)
    local code = httpGet(url)
    if not code or code == "" then
        warn("[REN] ❌ Fetch failed:", name); return false
    end
    local fn = loadstring or load
    if not fn then warn("[REN] ❌ No loadstring"); return false end
    local compiled, err = fn(code)
    if not compiled then warn("[REN] ❌ Compile:", name, err); return false end
    local ok, runErr = pcall(compiled)
    if not ok then warn("[REN] ❌ Run:", name, runErr); return false end
    print("[REN] ✅ Module OK:", name)
    return true
end

fetchModule("Database",     MODULES.Database)
fetchModule("Music",        MODULES.Music)
fetchModule("ScriptLoader", MODULES.ScriptLoader)

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  BOOT                                                              ║
-- ╚═══════════════════════════════════════════════════════════════════╝
if REN.bootMusic then REN.bootMusic() end
print("[REN] Music ready")

task.spawn(function()
    if os.time() - STATE.lastFullPush >= CONFIG.FullPushInterval then
        if REN.doFullPush then REN.doFullPush() end
    else
        print("[REN] 📊 Session recently pushed (skip)")
    end
end)

if REN.cleanupOld then REN.cleanupOld() end

if not STATE.heartbeatActive then
    STATE.heartbeatActive = true
    task.spawn(function()
        task.wait(2)
        while player and player.Parent do
            task.wait(30)
            if os.time() - STATE.lastHeartbeat >= CONFIG.TrackCooldown then
                STATE.lastHeartbeat = os.time()
                if REN.heartbeat then REN.heartbeat() end
            end
        end
        STATE.heartbeatActive = false
    end)
    print("[REN] 💓 Heartbeat loop started")
else
    print("[REN] 💓 Heartbeat already active (skip)")
end

player.AncestryChanged:Connect(function()
    if not player.Parent and REN.deleteSession then REN.deleteSession() end
end)

-- Auto-execute
local detectedMap = Maps[game.PlaceId]

task.spawn(function()
    task.wait(1)
    if detectedMap then
        local placeKey = tostring(game.PlaceId)
        local now = os.time()
        if STATE.lastAutoExec[placeKey] and (now - STATE.lastAutoExec[placeKey]) < CONFIG.AutoExecDebounce then
            local left = CONFIG.AutoExecDebounce - (now - STATE.lastAutoExec[placeKey])
            print("[REN] ⏭️ Skip auto-exec (debounce: " .. left .. "s left)")
            return
        end
        STATE.lastAutoExec[placeKey] = now
        print("[REN] Auto-exec:", detectedMap.name)
        toast("Loading", detectedMap.name)
        task.wait(0.3)
        local ok = REN.executeScript and REN.executeScript(detectedMap)
        if ok then
            toast("Success", detectedMap.name .. " loaded!")
        else
            task.wait(0.5)
            if REN.showBrowser then REN.showBrowser() end
        end
    else
        print("[REN] Map not supported → auto-browse")
        toast("Map Not Supported", "Opening browser...")
        task.wait(0.5)
        if REN.showBrowser then REN.showBrowser() end
    end
end)

print("[REN] ════════ READY v4.2 ════════")
