local REN = ((getgenv and getgenv()) or _G).REN
local pg = REN.pg
local TweenService = REN.TweenService

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

REN.toast = toast

print("[REN] ✅ Toast ready")
