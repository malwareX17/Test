getgenv().Config = {
    CameraLock = {
        Toggled = false,
        Smoothness = 0.9,
        DefaultPrediction = 0.135,
        AutoPrediction = true,
        TargetPart = "HumanoidRootPart"
    },
    FOV = {
        Visible = true,
        Radius = 150,
        Thickness = 20,
        Filled = false
    },
    Settings = {
        Keybind = Enum.KeyCode.Q
    },
    PredictionTable = {
        [30] = 0.12, [40] = 0.125, [50] = 0.13, [60] = 0.135, [70] = 0.14,
        [80] = 0.145, [90] = 0.15, [100] = 0.155, [110] = 0.16, [120] = 0.165,
        [130] = 0.17, [140] = 0.175
    }
}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local CurrentTarget = nil

--// FOV Circle Setup
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = getgenv().Config.FOV.Visible
FOVCircle.Radius = getgenv().Config.FOV.Radius
FOVCircle.Thickness = getgenv().Config.FOV.Thickness
FOVCircle.Filled = getgenv().Config.FOV.Filled
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local hue = 0
RunService.RenderStepped:Connect(function(dt)
    hue = (hue + dt * 0.2) % 1
    FOVCircle.Color = Color3.fromHSV(hue, 0.8, 0.8)
end)

--// Notification Function
local function Notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = 2;
    })
end

--// UI Setup
local screenGui = Instance.new("ScreenGui", game.CoreGui)
local button = Instance.new("TextButton", screenGui)
local ui = Instance.new("UICorner", button)

button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0, 10, 0, 10)
button.Font = Enum.Font.Arcade
button.TextSize = 16
button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
button.Active = true
button.Draggable = true
ui.CornerRadius = UDim.new(0, 5)

--// Improved Target Check (Checks if target is still valid)
local function isTargetValid(player)
    return player 
        and player.Character 
        and player.Character:FindFirstChild(getgenv().Config.CameraLock.TargetPart) 
        and player.Character:FindFirstChildOfClass("Humanoid") 
        and player.Character:FindFirstChildOfClass("Humanoid").Health > 0
end

--// Get Closest Player inside FOV
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isTargetValid(player) then
            local pos, onScreen = Camera:WorldToViewportPoint(player.Character[getgenv().Config.CameraLock.TargetPart].Position)
            
            if onScreen then
                local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                if distance < shortestDistance and distance < getgenv().Config.FOV.Radius then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end
    return closestPlayer
end

--// Toggle Function
local function ToggleLock()
    getgenv().Config.CameraLock.Toggled = not getgenv().Config.CameraLock.Toggled
    
    if getgenv().Config.CameraLock.Toggled then
        CurrentTarget = getClosestPlayer()
        if CurrentTarget then
            Notify("Locked On", CurrentTarget.DisplayName)
        else
            Notify("Searching", "No target in FOV")
            getgenv().Config.CameraLock.Toggled = false -- Reset if no one found
        end
    else
        if CurrentTarget then 
            Notify("Unlocked", CurrentTarget.DisplayName) 
        end
        CurrentTarget = nil
    end
end

button.MouseButton1Click:Connect(ToggleLock)

--// Main Loop
RunService.RenderStepped:Connect(function(dt)
    -- Update Rainbow Button
    local bHue = (tick() * 0.2) % 1
    button.TextColor3 = Color3.fromHSV(bHue, 0.8, 0.8)
    button.Text = "ProjectBanana | " .. (getgenv().Config.CameraLock.Toggled and "ON" or "OFF")
    
    -- Update FOV Circle Position
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Camera Lock Logic
    if getgenv().Config.CameraLock.Toggled and CurrentTarget then
        -- Verify target is still alive/in-game
        if isTargetValid(CurrentTarget) then
            local part = CurrentTarget.Character[getgenv().Config.CameraLock.TargetPart]
            local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            
            -- Find closest prediction value
            local predValue = getgenv().Config.CameraLock.DefaultPrediction
            local minDiff = math.huge
            for p, val in pairs(getgenv().Config.PredictionTable) do
                if math.abs(ping - p) < minDiff then
                    minDiff = math.abs(ping - p)
                    predValue = val
                end
            end
            
            local predictedPosition = part.Position + (part.Velocity * predValue)
            local targetCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
            
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, getgenv().Config.CameraLock.Smoothness)
        else
            -- Target died or left, stop locking
            CurrentTarget = nil
            getgenv().Config.CameraLock.Toggled = false
            Notify("Untargeted", "Target is no longer valid")
        end
    end
end)

UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == getgenv().Config.Settings.Keybind then
        ToggleLock()
    end
end)

Notify("ProjectBanana", "Inizialized")
