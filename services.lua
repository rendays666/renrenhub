local REN = ((getgenv and getgenv()) or _G).REN

local Players          = game:GetService("Players")
local HttpService      = game:GetService("HttpService")
local SoundService     = game:GetService("SoundService")
local TweenService     = game:GetService("TweenService")
local UIS              = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
if not player then return end
local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 10)
if not pg then return end

REN.Players            = Players
REN.HttpService        = HttpService
REN.SoundService       = SoundService
REN.TweenService       = TweenService
REN.UIS                = UIS
REN.MarketplaceService = MarketplaceService
REN.player             = player
REN.pg                 = pg

print("[REN] ✅ Services ready")
