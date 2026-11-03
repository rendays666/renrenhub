local env = (getgenv and getgenv()) or _G
env.REN = env.REN or {}
local STATE = env.REN

if not STATE.initialized then
    STATE.initialized     = true
    STATE.trackCache      = {}
    STATE.lastAutoExec    = {}
    STATE.lastFullPush    = 0
    STATE.lastHeartbeat   = 0
    STATE.lastCleanup     = 0
    STATE.cleanupRunning  = false
    STATE.heartbeatActive = false
    STATE.sessionDeleted  = false
end

STATE.lastReinject    = os.time()
STATE.sessionDeleted  = false

print("[REN] ✅ State ready")
