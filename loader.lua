--[[ RENRENHUB v4.2 — LOADER ]]
local BASE_URL = "https://raw.githubusercontent.com/rendays666/renrenscript/main/renrenhub/modules/"

local MODULES = {
    "state.lua",
    "config.lua",
    "services.lua",
    "http.lua",
    "gamename.lua",
    "toast.lua",
    "session.lua",
    "tracking.lua",
    "cleanup.lua",
    "image.lua",
    "executor.lua",
    "music.lua",
    "browser.lua",
    "boot.lua",
}

local env = (getgenv and getgenv()) or _G
env.REN = env.REN or {}
local STATE = env.REN

-- Reinject guard (< 10s → skip)
if STATE.lastReinject and STATE.lastReinject > 0 and (os.time() - STATE.lastReinject) < 10 then
    print("[REN] ⏭️ Skip reinject (< 10s)")
    return
end

for _, file in ipairs(MODULES) do
    local url = BASE_URL .. file
    local ok, code = pcall(function() return game:HttpGet(url, true) end)
    if not ok or not code or code == "" then
        warn("[REN] ❌ Fetch failed: " .. file)
        continue
    end
    local fn, err = loadstring(code)
    if not fn then
        warn("[REN] ❌ Compile failed: " .. file .. " — " .. tostring(err))
        continue
    end
    local runOk, runErr = pcall(fn)
    if not runOk then
        warn("[REN] ❌ Runtime failed: " .. file .. " — " .. tostring(runErr))
        continue
    end
    print("[REN] ✅ " .. file)
end

print("[REN] ════════ ALL MODULES LOADED ════════")
