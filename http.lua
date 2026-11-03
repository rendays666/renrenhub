local REN = ((getgenv and getgenv()) or _G).REN
local HttpService = REN.HttpService
local CONFIG = REN.CONFIG

local function httpReq(url, method, body)
    local p = {
        Url = url, Method = method,
        Headers = {["Content-Type"] = "application/json"},
        Body = body,
    }
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

REN.httpReq     = httpReq
REN.httpGet     = httpGet
REN.firebaseReq = firebaseReq

print("[REN] ✅ HTTP ready")
