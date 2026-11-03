-- RENRENHUB v4.2 — DATABASE MODULE
-- Firebase, session PUT, heartbeat, track execute, cleanup
local REN = (getgenv and getgenv()).REN or _G.REN
if not REN then error("[REN] Loader belum dijalankan") end

local CONFIG   = REN.CONFIG
local STATE    = REN
local player   = REN.player
local HttpService = REN.HttpService
local firebaseReq = REN.firebaseReq
local httpReq  = REN.httpReq
local httpGet  = REN.httpGet
local getGameName = REN.getGameName

local sessionId = tostring(player.UserId)
local heartbeatInFlight = false

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  FULL SESSION PUT                                                  ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local function doFullPush()
    pcall(function()
        local now = os.time()
        local jobId = game.JobId
        if not jobId or jobId == "" then jobId = "Studio" end
        local placeId = tostring(game.PlaceId)

        local data = {
            username = player.Name, userId = player.UserId,
            placeId = placeId, jobId = jobId,
            gameName = getGameName(),
            joinUrl = "https://www.roblox.com/games/start?placeId=" .. placeId .. "&gameInstanceId=" .. jobId,
            profileUrl = "https://www.roblox.com/users/" .. player.UserId .. "/profile",
            executor = (identifyexecutor and identifyexecutor()) or "Unknown",
            status = "active", timestamp = now, sessionId = sessionId,
        }

        local res = firebaseReq("PUT", "/sessions/" .. sessionId .. ".json", data)
        if res then
            STATE.lastFullPush = now
            print("[REN] 📊 Session PUT OK (full)")
        else
            warn("[REN] ❌ Session PUT failed")
        end
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  HEARTBEAT                                                         ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local function heartbeat()
    if heartbeatInFlight then return end
    heartbeatInFlight = true
    task.spawn(function()
        pcall(function()
            local now = os.time()
            if now - STATE.lastFullPush >= CONFIG.FullPushInterval then
                doFullPush()
            else
                firebaseReq("PUT", "/sessions/" .. sessionId .. "/timestamp.json", now)
            end
        end)
        heartbeatInFlight = false
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  DELETE SESSION                                                    ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local function deleteSession()
    if STATE.sessionDeleted then return end
    STATE.sessionDeleted = true
    task.spawn(function()
        pcall(function()
            local res = firebaseReq("DELETE", "/sessions/" .. sessionId .. ".json")
            if not res then
                firebaseReq("PUT", "/sessions/" .. sessionId .. "/timestamp.json", 0)
                print("[REN] ⚠️ DELETE failed, marked stale")
            end
        end)
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  TRACK EXECUTE                                                     ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local function trackExecute(scriptCfg)
    local placeKey = tostring(game.PlaceId)
    local now = os.time()

    if STATE.trackCache[placeKey] and (now - STATE.trackCache[placeKey]) < CONFIG.TrackDebounce then
        print("[REN] ⏭️ Skip track (debounce: " ..
            (CONFIG.TrackDebounce - (now - STATE.trackCache[placeKey])) .. "s left)")
        return
    end
    STATE.trackCache[placeKey] = now

    task.spawn(function()
        pcall(function()
            local gameName = getGameName()
            local key = now .. "_" .. player.UserId .. "_" .. math.random(1000, 9999)

            local payload = {
                ["executes/" .. key] = {
                    username = player.Name, userId = player.UserId,
                    placeId = placeKey, gameName = gameName,
                    scriptName = scriptCfg and scriptCfg.name or "Unknown",
                    timestamp = now,
                },
                ["stats/totalExecutes"] = {[".sv"] = {increment = 1}},
                ["stats/byGame/" .. placeKey .. "/count"] = {[".sv"] = {increment = 1}},
                ["stats/byGame/" .. placeKey .. "/name"] = gameName,
                ["stats/updatedAt"] = now,
            }

            local res = httpReq(CONFIG.FirebaseURL .. "/.json", "PATCH",
                HttpService:JSONEncode(payload))
            if res then
                print("[REN] ✅ Tracked | Map:", gameName)
            else
                warn("[REN] ❌ Track failed")
            end
        end)
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  CLEANUP                                                           ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local function cleanupOld()
    if STATE.cleanupRunning then return end
    STATE.cleanupRunning = true

    task.spawn(function()
        pcall(function()
            local lastRaw = httpGet(CONFIG.FirebaseURL .. "/config/lastCleanup.json")
            local last = tonumber(lastRaw) or 0
            if os.time() - last < CONFIG.CleanupCooldown then
                STATE.cleanupRunning = false; return
            end
            firebaseReq("PUT", "/config/lastCleanup.json", os.time())
            print("[REN] 🧹 Running cleanup...")

            local cutoff = os.time() - CONFIG.ExecutesTTL
            local url = CONFIG.FirebaseURL .. '/executes.json?orderBy="timestamp"&endAt=' .. cutoff
            local res = httpReq(url, "GET", nil)
            if res and res.Body and res.Body ~= "null" then
                local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
                if ok and type(data) == "table" then
                    local count = 0
                    for k in pairs(data) do
                        firebaseReq("DELETE", "/executes/" .. k .. ".json")
                        count = count + 1
                        if count >= 200 then break end
                    end
                    if count > 0 then print("[REN] 🧹 Cleaned " .. count .. " old executes") end
                end
            end

            local sessRes = httpReq(CONFIG.FirebaseURL .. "/sessions.json", "GET", nil)
            if sessRes and sessRes.Body and sessRes.Body ~= "null" then
                local ok, data = pcall(function() return HttpService:JSONDecode(sessRes.Body) end)
                if ok and type(data) == "table" then
                    local count = 0
                    for k, s in pairs(data) do
                        if type(s) == "table" and k ~= sessionId then
                            local isStale = s.timestamp and (os.time() - s.timestamp) > CONFIG.SessionTimeout
                            local isOldFormat = k:match("^%d+_%d+$") ~= nil
                            if isStale or isOldFormat then
                                firebaseReq("DELETE", "/sessions/" .. k .. ".json")
                                count = count + 1
                                if count >= 200 then break end
                            end
                        end
                    end
                    if count > 0 then print("[REN] 🧹 Cleaned " .. count .. " stale/old sessions") end
                end
            end
        end)
        STATE.cleanupRunning = false
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  EXPORT                                                            ║
-- ╚═══════════════════════════════════════════════════════════════════╝
REN.doFullPush     = doFullPush
REN.heartbeat      = heartbeat
REN.deleteSession  = deleteSession
REN.trackExecute   = trackExecute
REN.cleanupOld     = cleanupOld

print("[REN] ✅ Database module loaded")
