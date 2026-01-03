getgenv().Config = {
    CameraLock = {
        Toggled = false,
        Smoothness = 0.1,
        DefaultPrediction = 0.15,
        AutoPrediction = true,
        TargetPart = "HumanoidRootPart"
    },
    FOV = {
        Visible = true,
        Radius = 150,
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
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
FOVCircle.Color = getgenv().Config.FOV.Color
FOVCircle.Thickness = getgenv().Config.FOV.Thickness
FOVCircle.Filled = getgenv().Config.FOV.Filled
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

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
button.Font = Enum.Font.GothamBlack
button.TextScaled = true
button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
button.Active = true
button.Draggable = true
ui.CornerRadius = UDim.new(0, 5)

--// Get Closest Player inside FOV
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = math.huge
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(getgenv().Config.CameraLock.TargetPart) then
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
        local target = getClosestPlayer()
        Notify("Targeting", target and target.DisplayName or "Searching...")
    else
        if CurrentTarget then Notify("Untargeting", CurrentTarget.Name) end
    end
end

button.MouseButton1Click:Connect(ToggleLock)

--// Main Loop
RunService.RenderStepped:Connect(function(dt)
    -- Update Rainbow Button
    local hue = (tick() * 0.2) % 1
    button.TextColor3 = Color3.fromHSV(hue, 0.8, 0.8)
    button.Text = "ProjectBanana | " .. (getgenv().Config.CameraLock.Toggled and "ON" or "OFF")
    
    -- Update FOV Circle Position
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    -- Camera Lock Logic
    if getgenv().Config.CameraLock.Toggled then
        local target = getClosestPlayer()
        if target and target.Character then
            CurrentTarget = target
            local part = target.Character[getgenv().Config.CameraLock.TargetPart]
            local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            
            -- Find closest prediction value from table
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
        end
    else
        CurrentTarget = nil
    end
end)

UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == getgenv().Config.Settings.Keybind then
        ToggleLock()
    end
end)

Notify("ProjectBanana", "FOV & Button Ready")
