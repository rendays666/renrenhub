local REN = ((getgenv and getgenv()) or _G).REN
local HttpService = REN.HttpService
local MarketplaceService = REN.MarketplaceService

local cachedGameName = nil

local function getGameName()
    if cachedGameName then return cachedGameName end
    local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    if ok and info and info.Name and info.Name ~= "" then
        cachedGameName = info.Name
        return cachedGameName
    end
    local ok2, res = pcall(function()
        return game:HttpGet("https://games.roblox.com/v1/games?universeIds=" .. tostring(game.GameId))
    end)
    if ok2 and res then
        local ok3, data = pcall(function() return HttpService:JSONDecode(res) end)
        if ok3 and data and data.data and data.data[1] and data.data[1].name then
            cachedGameName = data.data[1].name
            return cachedGameName
        end
    end
    cachedGameName = "Game #" .. tostring(game.PlaceId)
    return cachedGameName
end

REN.getGameName = getGameName

print("[REN] ✅ GameName ready")
