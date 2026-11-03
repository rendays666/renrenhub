-- RENRENHUB v4.2 — SCRIPT LOADER MODULE
-- Executor script, browser UI, image resolver
local REN = (getgenv and getgenv()).REN or _G.REN
if not REN then error("[REN] Loader belum dijalankan") end

local CONFIG        = REN.CONFIG
local Maps          = REN.Maps
local UniversalScripts = REN.UniversalScripts
local MarketplaceService = REN.MarketplaceService
local HttpService   = REN.HttpService
local pg            = REN.pg
local toast         = REN.toast
local httpGet       = REN.httpGet

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  IMAGE RESOLVER                                                    ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local function fetchUniverseId(placeId)
    for _, fmt in ipairs({
        "https://apis.roblox.com/universes/v1/places/%d/universe",
        "https://apis.roproxy.com/universes/v1/places/%d/universe",
    }) do
        local body = httpGet(string.format(fmt, placeId))
        if body then
            local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
            if ok and type(data) == "table" and tonumber(data.universeId) then
                return tonumber(data.universeId)
            end
        end
    end
    return nil
end

local function resolveImage(cfg, placeId, setImage)
    if cfg._imgCache and cfg._imgCache ~= "" then setImage(cfg._imgCache); return end
    if cfg.imageUrl and cfg.imageUrl ~= "" then
        cfg._imgCache = cfg.imageUrl; setImage(cfg._imgCache); return
    end
    task.spawn(function()
        local uid = tonumber(cfg.universeId)
        if not uid or uid <= 0 then
            if placeId == game.PlaceId then uid = game.GameId
            elseif placeId then uid = fetchUniverseId(placeId) end
        end
        if uid and uid > 0 then
            cfg._imgCache = "rbxthumb://type=GameIcon&id=" .. uid .. "&w=420&h=420"
            setImage(cfg._imgCache); return
        end
        local pid = placeId or game.PlaceId
        local ok, info = pcall(function() return MarketplaceService:GetProductInfo(pid) end)
        if ok and info and tonumber(info.IconImageAssetId) and tonumber(info.IconImageAssetId) > 0 then
            cfg._imgCache = "rbxassetid://" .. tostring(info.IconImageAssetId)
            setImage(cfg._imgCache)
        end
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  EXECUTE SCRIPT                                                    ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local function executeScript(cfg)
    if not cfg or not cfg.scriptUrl then
        toast("Error", "No script URL"); return false
    end
    print("[REN] Executing:", cfg.name)

    local code = httpGet(cfg.scriptUrl)
    if not code then toast("Error", "Download failed"); return false end

    local fn = loadstring or load
    if not fn then toast("Error", "No loadstring"); return false end

    local compiled, err = fn(code)
    if not compiled then
        warn("[REN] Compile:", err)
        toast("Error", "Compile error"); return false
    end

    local ok, runErr = pcall(compiled)
    if not ok then
        warn("[REN] Runtime:", runErr)
        toast("Error", "Runtime error"); return false
    end

    if REN.trackExecute then REN.trackExecute(cfg) end
    print("[REN] ✅ Script executed + tracked")
    return true
end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  BROWSER UI                                                        ║
-- ╚═══════════════════════════════════════════════════════════════════╝
local function showBrowser()
    local old = pg:FindFirstChild("REN_Browser"); if old then old:Destroy() end
    local gui = Instance.new("ScreenGui")
    gui.Name = "REN_Browser"; gui.ResetOnSpawn = false
    gui.DisplayOrder = 500; gui.Parent = pg

    local bd = Instance.new("Frame", gui)
    bd.Size = UDim2.new(1, 0, 1, 0)
    bd.BackgroundColor3 = Color3.new(0, 0, 0)
    bd.BackgroundTransparency = 0.5; bd.BorderSizePixel = 0; bd.Active = true

    local panel = Instance.new("Frame", gui)
    panel.Size = UDim2.new(0, 720, 0, 400)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.new(0.5, 0, 0.5, 0)
    panel.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
    panel.BorderSizePixel = 0; panel.Active = true
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)
    local pStroke = Instance.new("UIStroke", panel)
    pStroke.Color = Color3.fromRGB(0, 220, 160); pStroke.Thickness = 2

    local tb = Instance.new("Frame", panel)
    tb.Size = UDim2.new(1, 0, 0, 52)
    tb.BackgroundColor3 = Color3.fromRGB(28, 32, 48); tb.BorderSizePixel = 0
    Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 16)

    local title = Instance.new("TextLabel", tb)
    title.Size = UDim2.new(1, -70, 1, 0); title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1; title.Text = "Select Script"
    title.TextColor3 = Color3.fromRGB(0, 220, 160)
    title.Font = Enum.Font.GothamBold; title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left

    local hint = Instance.new("TextLabel", tb)
    hint.Size = UDim2.new(1, -70, 0, 14); hint.Position = UDim2.new(0, 20, 0, 30)
    hint.BackgroundTransparency = 1; hint.Text = "← Swipe cards →"
    hint.TextColor3 = Color3.fromRGB(140, 150, 170)
    hint.Font = Enum.Font.Gotham; hint.TextSize = 10
    hint.TextXAlignment = Enum.TextXAlignment.Left

    local xBtn = Instance.new("TextButton", tb)
    xBtn.Size = UDim2.new(0, 36, 0, 36); xBtn.Position = UDim2.new(1, -46, 0, 8)
    xBtn.BackgroundColor3 = Color3.fromRGB(200, 55, 55)
    xBtn.Text = "×"; xBtn.TextColor3 = Color3.new(1, 1, 1)
    xBtn.Font = Enum.Font.GothamBold; xBtn.TextSize = 22; xBtn.BorderSizePixel = 0
    Instance.new("UICorner", xBtn).CornerRadius = UDim.new(0, 8)
    xBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

    local scroll = Instance.new("ScrollingFrame", panel)
    scroll.Size = UDim2.new(1, -40, 1, -100)
    scroll.Position = UDim2.new(0, 20, 0, 72)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 220, 160)
    scroll.ScrollingDirection = Enum.ScrollingDirection.X
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.X

    local layout = Instance.new("UIListLayout", scroll)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 14)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    local all = {}
    for placeId, cfg in pairs(Maps) do table.insert(all, {cfg = cfg, placeId = placeId}) end
    for _, cfg in ipairs(UniversalScripts) do table.insert(all, {cfg = cfg, placeId = nil}) end

    for i, entry in ipairs(all) do
        local card = Instance.new("Frame", scroll)
        card.Size = UDim2.new(0, 195, 1, -12)
        card.BackgroundColor3 = Color3.fromRGB(28, 33, 50)
        card.BorderSizePixel = 0; card.LayoutOrder = i
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

        local imgBox = Instance.new("Frame", card)
        imgBox.Size = UDim2.new(1, -16, 0, 115)
        imgBox.Position = UDim2.new(0, 8, 0, 8)
        imgBox.BackgroundColor3 = Color3.fromRGB(40, 46, 66)
        imgBox.BorderSizePixel = 0; imgBox.ClipsDescendants = true
        Instance.new("UICorner", imgBox).CornerRadius = UDim.new(0, 10)

        local ph = Instance.new("TextLabel", imgBox)
        ph.Size = UDim2.new(1, 0, 1, 0); ph.BackgroundTransparency = 1
        ph.Text = string.upper(string.sub(entry.cfg.name or "?", 1, 2))
        ph.TextColor3 = Color3.fromRGB(90, 110, 150)
        ph.Font = Enum.Font.GothamBold; ph.TextSize = 36

        local img = Instance.new("ImageLabel", imgBox)
        img.Size = UDim2.new(1, 0, 1, 0); img.BackgroundTransparency = 1
        img.Image = ""; img.ScaleType = Enum.ScaleType.Crop; img.ZIndex = 2
        Instance.new("UICorner", img).CornerRadius = UDim.new(0, 10)

        resolveImage(entry.cfg, entry.placeId, function(url)
            if img.Parent then img.Image = url; ph.Visible = false end
        end)

        local nm = Instance.new("TextLabel", card)
        nm.Size = UDim2.new(1, -16, 0, 20); nm.Position = UDim2.new(0, 8, 0, 132)
        nm.BackgroundTransparency = 1; nm.Text = entry.cfg.name or "Unknown"
        nm.TextColor3 = Color3.fromRGB(240, 240, 250)
        nm.Font = Enum.Font.GothamBold; nm.TextSize = 14
        nm.TextXAlignment = Enum.TextXAlignment.Left
        nm.TextTruncate = Enum.TextTruncate.AtEnd

        local ds = Instance.new("TextLabel", card)
        ds.Size = UDim2.new(1, -16, 0, 32); ds.Position = UDim2.new(0, 8, 0, 154)
        ds.BackgroundTransparency = 1; ds.Text = entry.cfg.description or ""
        ds.TextColor3 = Color3.fromRGB(150, 160, 180)
        ds.Font = Enum.Font.Gotham; ds.TextSize = 11
        ds.TextXAlignment = Enum.TextXAlignment.Left
        ds.TextYAlignment = Enum.TextYAlignment.Top
        ds.TextWrapped = true

        local ex = Instance.new("TextButton", card)
        ex.Size = UDim2.new(1, -16, 0, 36); ex.Position = UDim2.new(0, 8, 1, -44)
        ex.BackgroundColor3 = Color3.fromRGB(0, 200, 140)
        ex.Text = "▶ Execute"; ex.TextColor3 = Color3.new(1, 1, 1)
        ex.Font = Enum.Font.GothamBold; ex.TextSize = 13; ex.BorderSizePixel = 0
        Instance.new("UICorner", ex).CornerRadius = UDim.new(0, 8)

        ex.MouseButton1Click:Connect(function()
            gui:Destroy()
            task.wait(0.2)
            local ok = executeScript(entry.cfg)
            if ok then toast("Success", entry.cfg.name .. " loaded!") end
        end)
    end
end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  EXPORT                                                            ║
-- ╚═══════════════════════════════════════════════════════════════════╝
REN.executeScript = executeScript
REN.showBrowser   = showBrowser

print("[REN] ✅ ScriptLoader module loaded")
