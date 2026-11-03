-- RENRENHUB v4.2 — MUSIC MODULE
-- Music player 3-state + UI + playlist loop
local REN = (getgenv and getgenv()).REN or _G.REN
if not REN then error("[REN] Loader belum dijalankan") end

local CONFIG       = REN.CONFIG
local Playlist     = REN.Playlist
local SoundService = REN.SoundService
local pg           = REN.pg
local UIS          = REN.UIS

local musicSound = SoundService:FindFirstChild("__REN_Music")
local musicState = 1
local currentIndex = 1
local musicVolume = CONFIG.MusicVolume
local musicPaused = false
local savedVols = {}
local mutedState = {value = true}

-- ┌───────────────────────────────────────────────────────────────┐
-- │  GAME SOUND MUTE / RESTORE                                    │
-- └───────────────────────────────────────────────────────────────┘
local function saveGameSounds(except)
    savedVols = {}
    for _, root in ipairs({SoundService, workspace, game:GetService("Lighting")}) do
        if root then
            pcall(function()
                for _, s in ipairs(root:GetDescendants()) do
                    if s:IsA("Sound") and s ~= except and s.Name ~= "__REN_Music" then
                        savedVols[s] = s.Volume
                    end
                end
            end)
        end
    end
end

local function setSoundsVol(mute, except)
    for s, v in pairs(savedVols) do
        if s ~= except and s and s.Parent then
            pcall(function() s.Volume = mute and 0 or v end)
        end
    end
end

local function tryWatch(o)
    if o:IsA("Sound") and o ~= musicSound and o.Name ~= "__REN_Music" and not savedVols[o] then
        savedVols[o] = o.Volume
        if mutedState.value then pcall(function() o.Volume = 0 end) end
    end
end

local function applyMusicState()
    if musicState == 1 then
        setSoundsVol(true, musicSound); mutedState.value = true
        if musicSound then musicSound.Volume = musicVolume end
        if musicSound and musicSound.SoundId ~= "" and not musicPaused and not musicSound.Playing then
            pcall(function() musicSound:Play() end)
        end
    elseif musicState == 2 then
        setSoundsVol(false, musicSound); mutedState.value = false
        if musicSound then musicSound.Volume = musicVolume end
        if musicSound and musicSound.SoundId ~= "" and not musicPaused and not musicSound.Playing then
            pcall(function() musicSound:Play() end)
        end
    else
        setSoundsVol(false, musicSound); mutedState.value = false
        if musicSound then musicSound.Volume = 0 end
    end
end

local function getModeText()
    if musicState == 1 then return "🎵 Music Only"
    elseif musicState == 2 then return "🎵🔊 Music + Game"
    else return "🔊 Game Only" end
end

local function getModeColor()
    if musicState == 1 then return Color3.fromRGB(40, 42, 55)
    elseif musicState == 2 then return Color3.fromRGB(60, 90, 60)
    else return Color3.fromRGB(90, 60, 60) end
end

local function playSongAt(idx)
    if not musicSound or not musicSound.Parent then return end
    currentIndex = ((idx - 1) % #Playlist) + 1
    local entry = Playlist[currentIndex]
    musicPaused = false
    pcall(function() musicSound:Stop() end)
    musicSound.SoundId = entry.id
    musicSound.Volume = (musicState == 3) and 0 or musicVolume
    task.spawn(function()
        task.wait(0.15)
        pcall(function() musicSound:Play() end)
    end)
end

-- ┌───────────────────────────────────────────────────────────────┐
-- │  INIT MUSIC                                                    │
-- └───────────────────────────────────────────────────────────────┘
local function initMusic()
    if musicSound and musicSound.Parent then
        print("[REN] 🎵 Music already running (skip init)"); return
    end
    musicSound = Instance.new("Sound")
    musicSound.Name = "__REN_Music"
    musicSound.Volume = musicVolume
    musicSound.Looped = false
    musicSound.Parent = SoundService
    musicSound.Ended:Connect(function()
        if not musicPaused then playSongAt(currentIndex + 1) end
    end)
    saveGameSounds(musicSound)
    applyMusicState()
    SoundService.DescendantAdded:Connect(tryWatch)
    workspace.DescendantAdded:Connect(tryWatch)
    playSongAt(1)
end

-- ┌───────────────────────────────────────────────────────────────┐
-- │  MUSIC UI                                                      │
-- └───────────────────────────────────────────────────────────────┘
local function createMusicUI()
    if pg:FindFirstChild("REN_MusicUI") then
        print("[REN] 🎵 Music UI already exists (skip)"); return
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "REN_MusicUI"; gui.ResetOnSpawn = false
    gui.DisplayOrder = 250; gui.Parent = pg

    local icon = Instance.new("TextButton", gui)
    icon.Size = UDim2.new(0, 54, 0, 54)
    icon.Position = UDim2.new(0, 16, 0.5, -27)
    icon.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
    icon.Text = "🎵"; icon.TextSize = 24
    icon.BorderSizePixel = 0; icon.AutoButtonColor = false
    Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
    local is = Instance.new("UIStroke", icon)
    is.Color = Color3.fromRGB(0, 220, 160); is.Thickness = 2

    local panel = Instance.new("Frame", gui)
    panel.Size = UDim2.new(0, 290, 0, 145)
    panel.Position = UDim2.new(0, 16, 0.5, -72)
    panel.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
    panel.BorderSizePixel = 0; panel.Visible = false
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
    local ps = Instance.new("UIStroke", panel)
    ps.Color = Color3.fromRGB(0, 220, 160); ps.Thickness = 2

    local header = Instance.new("Frame", panel)
    header.Size = UDim2.new(1, 0, 0, 32)
    header.BackgroundTransparency = 1; header.Active = true

    local hTitle = Instance.new("TextLabel", header)
    hTitle.Size = UDim2.new(1, -70, 1, 0); hTitle.Position = UDim2.new(0, 12, 0, 0)
    hTitle.BackgroundTransparency = 1; hTitle.Text = "🎵 Music Player"
    hTitle.TextColor3 = Color3.fromRGB(0, 220, 160)
    hTitle.Font = Enum.Font.GothamBold; hTitle.TextSize = 12
    hTitle.TextXAlignment = Enum.TextXAlignment.Left

    local colBtn = Instance.new("TextButton", header)
    colBtn.Size = UDim2.new(0, 24, 0, 22); colBtn.Position = UDim2.new(1, -56, 0, 5)
    colBtn.BackgroundColor3 = Color3.fromRGB(50, 56, 76)
    colBtn.Text = "−"; colBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
    colBtn.Font = Enum.Font.GothamBold; colBtn.TextSize = 14; colBtn.BorderSizePixel = 0
    Instance.new("UICorner", colBtn).CornerRadius = UDim.new(0, 4)

    local xBtn = Instance.new("TextButton", header)
    xBtn.Size = UDim2.new(0, 24, 0, 22); xBtn.Position = UDim2.new(1, -28, 0, 5)
    xBtn.BackgroundColor3 = Color3.fromRGB(200, 55, 55)
    xBtn.Text = "×"; xBtn.TextColor3 = Color3.new(1, 1, 1)
    xBtn.Font = Enum.Font.GothamBold; xBtn.TextSize = 14; xBtn.BorderSizePixel = 0
    Instance.new("UICorner", xBtn).CornerRadius = UDim.new(0, 4)

    local songLbl = Instance.new("TextLabel", panel)
    songLbl.Size = UDim2.new(1, -24, 0, 22); songLbl.Position = UDim2.new(0, 12, 0, 34)
    songLbl.BackgroundTransparency = 1; songLbl.Text = Playlist[1].name
    songLbl.TextColor3 = Color3.fromRGB(240, 240, 250)
    songLbl.Font = Enum.Font.GothamBold; songLbl.TextSize = 13
    songLbl.TextXAlignment = Enum.TextXAlignment.Left
    songLbl.TextTruncate = Enum.TextTruncate.AtEnd

    local prevBtn = Instance.new("TextButton", panel)
    prevBtn.Size = UDim2.new(0, 44, 0, 44); prevBtn.Position = UDim2.new(0, 12, 0, 60)
    prevBtn.BackgroundColor3 = Color3.fromRGB(40, 46, 66)
    prevBtn.Text = "⏮"; prevBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
    prevBtn.TextSize = 22; prevBtn.BorderSizePixel = 0
    Instance.new("UICorner", prevBtn).CornerRadius = UDim.new(0, 10)

    local playBtn = Instance.new("TextButton", panel)
    playBtn.Size = UDim2.new(0, 64, 0, 44); playBtn.Position = UDim2.new(0, 62, 0, 60)
    playBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 140)
    playBtn.Text = "⏸"; playBtn.TextColor3 = Color3.new(1, 1, 1)
    playBtn.TextSize = 22; playBtn.BorderSizePixel = 0
    Instance.new("UICorner", playBtn).CornerRadius = UDim.new(0, 10)

    local nextBtn = Instance.new("TextButton", panel)
    nextBtn.Size = UDim2.new(0, 44, 0, 44); nextBtn.Position = UDim2.new(0, 132, 0, 60)
    nextBtn.BackgroundColor3 = Color3.fromRGB(40, 46, 66)
    nextBtn.Text = "⏭"; nextBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
    nextBtn.TextSize = 22; nextBtn.BorderSizePixel = 0
    Instance.new("UICorner", nextBtn).CornerRadius = UDim.new(0, 10)

    local modeBtn = Instance.new("TextButton", panel)
    modeBtn.Size = UDim2.new(0, 140, 0, 26); modeBtn.Position = UDim2.new(0, 12, 1, -34)
    modeBtn.BackgroundColor3 = getModeColor()
    modeBtn.Text = getModeText()
    modeBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
    modeBtn.Font = Enum.Font.Gotham; modeBtn.TextSize = 11; modeBtn.BorderSizePixel = 0
    Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 6)

    local volBtn = Instance.new("TextButton", panel)
    volBtn.Size = UDim2.new(0, 110, 0, 26); volBtn.Position = UDim2.new(1, -122, 1, -34)
    volBtn.BackgroundColor3 = Color3.fromRGB(40, 46, 66)
    volBtn.Text = "🔊 " .. math.floor(musicVolume * 100) .. "%"
    volBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
    volBtn.Font = Enum.Font.Gotham; volBtn.TextSize = 11; volBtn.BorderSizePixel = 0
    Instance.new("UICorner", volBtn).CornerRadius = UDim.new(0, 6)

    local function updateUI()
        songLbl.Text = Playlist[currentIndex] and Playlist[currentIndex].name or "-"
        playBtn.Text = musicPaused and "▶" or "⏸"
        playBtn.BackgroundColor3 = musicPaused and Color3.fromRGB(200, 150, 50) or Color3.fromRGB(0, 200, 140)
        modeBtn.Text = getModeText()
        modeBtn.BackgroundColor3 = getModeColor()
        volBtn.Text = "🔊 " .. math.floor(musicVolume * 100) .. "%"
    end

    icon.MouseButton1Click:Connect(function() icon.Visible = false; panel.Visible = true; updateUI() end)
    colBtn.MouseButton1Click:Connect(function() panel.Visible = false; icon.Visible = true end)
    xBtn.MouseButton1Click:Connect(function() if musicSound then musicSound:Destroy() end; gui:Destroy() end)
    prevBtn.MouseButton1Click:Connect(function() playSongAt(currentIndex - 1); task.wait(0.1); updateUI() end)
    playBtn.MouseButton1Click:Connect(function()
        if musicPaused then
            musicPaused = false
            pcall(function() musicSound:Resume() end)
        else
            musicPaused = true
            pcall(function() musicSound:Pause() end)
        end
        updateUI()
    end)
    nextBtn.MouseButton1Click:Connect(function() playSongAt(currentIndex + 1); task.wait(0.1); updateUI() end)
    modeBtn.MouseButton1Click:Connect(function()
        musicState = (musicState % 3) + 1
        applyMusicState()
        if musicSound and musicSound.SoundId ~= "" then
            if musicState == 3 then
                musicSound.Volume = 0
            else
                musicSound.Volume = musicVolume
                if not musicPaused and not musicSound.Playing then
                    pcall(function() musicSound:Play() end)
                end
            end
        end
        updateUI()
    end)
    volBtn.MouseButton1Click:Connect(function()
        musicVolume = musicVolume + 0.1
        if musicVolume > 1.05 then musicVolume = 0 end
        musicVolume = math.clamp(musicVolume, 0, 1)
        if musicSound and musicState ~= 3 then musicSound.Volume = musicVolume end
        updateUI()
    end)

    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = panel.Position
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    task.spawn(function()
        while gui.Parent do task.wait(0.5); updateUI() end
    end)
end

-- ╔═══════════════════════════════════════════════════════════════════╗
-- ║  EXPORT                                                            ║
-- ╚═══════════════════════════════════════════════════════════════════╝
REN.bootMusic = function()
    initMusic()
    createMusicUI()
end

print("[REN] ✅ Music module loaded")
