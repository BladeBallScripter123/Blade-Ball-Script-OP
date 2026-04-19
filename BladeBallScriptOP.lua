local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local revertedRemotes = {}
local spamEnabled = false

local function isValidArgs(args)
    return #args == 7 and typeof(args[4]) == "CFrame"
end

local function hookRemote(remote)
    local mt = getrawmetatable(remote)
    if not mt then return end

    setreadonly(mt, false)
    local old = mt.__index

    mt.__index = function(self, key)
        if key == "FireServer" then
            return function(obj, ...)
                local args = {...}

                if isValidArgs(args) and not revertedRemotes[obj] then
                    revertedRemotes[obj] = args
                end

                return old(self, key)(obj, ...)
            end
        end

        return old(self, key)
    end

    setreadonly(mt, true)
end

for _, v in pairs(ReplicatedStorage:GetDescendants()) do
    if v:IsA("RemoteEvent") then
        hookRemote(v)
    end
end

ReplicatedStorage.DescendantAdded:Connect(function(v)
    if v:IsA("RemoteEvent") then
        hookRemote(v)
    end
end)

local function getClosestPlayer(root)
    local closest = nil
    local dist = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local mag = (player.Character.HumanoidRootPart.Position - root.Position).Magnitude
            if mag < dist then
                dist = mag
                closest = player
            end
        end
    end

    return closest
end

local function getCrosshairPlayer()
    local closest = nil
    local closestDot = -1

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart

            local direction = (rootPart.Position - Camera.CFrame.Position).Unit
            local dot = direction:Dot(Camera.CFrame.LookVector)

            if dot > closestDot then
                closestDot = dot
                closest = player
            end
        end
    end

    return closest
end

local function doParry()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
local targetPlayer = getCrosshairPlayer() 

local targetRoot = nil
if targetPlayer and targetPlayer.Character then
    targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
end 

if not targetRoot then
    targetRoot = root
end

    for remote, args in pairs(revertedRemotes) do
        local targets = {}

        for k, v in pairs(args[5]) do
            if typeof(v) == "Vector3" then

                local dist = (v - targetRoot.Position).Magnitude

                if dist < 10 then
                    targets[k] = targetRoot.Position
                else
                    targets[k] = v
                end
            else
                targets[k] = v
            end
        end

        local newArgs = {
            args[1],
            args[2],
            args[3],
            Camera.CFrame,
            targets,
            args[6],
            args[7]
        }

        pcall(function()
            remote:FireServer(unpack(newArgs))
        end)
    end
end

task.spawn(function()
    while true do
        if spamEnabled then
            doParry()
            task.wait(0.001)
        else
            task.wait(0.1)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.G then
        spamEnabled = not spamEnabled
        if toggle then
    toggle.Text = spamEnabled and "SPAM: ON" or "SPAM: OFF"
      end
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "UI"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui 

local main = Instance.new("Frame")
main.Parent = gui
main.Size = UDim2.new(0, 360, 0, 220)
main.Position = UDim2.new(0.05, 0, 0.35, 0)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true 

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8) 

local top = Instance.new("Frame")
top.Parent = main
top.Size = UDim2.new(1, 0, 0, 32)
top.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
top.BorderSizePixel = 0 

Instance.new("UICorner", top).CornerRadius = UDim.new(0, 8) 

local title = Instance.new("TextLabel")
title.Parent = top
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "PARRY SYSTEM"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 14 

local tabs = Instance.new("Frame")
tabs.Parent = main
tabs.Size = UDim2.new(0, 100, 1, -32)
tabs.Position = UDim2.new(0, 0, 0, 32)
tabs.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
tabs.BorderSizePixel = 0 

local content = Instance.new("Frame")
content.Parent = main
content.Size = UDim2.new(1, -100, 1, -32)
content.Position = UDim2.new(0, 100, 0, 32)
content.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
content.BorderSizePixel = 0 

local function createTab(name, y)
    local btn = Instance.new("TextButton")
    btn.Parent = tabs
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200,200,200)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12 

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end 

createTab("MAIN", 5) 

local toggle = Instance.new("TextButton")
toggle.Parent = content
toggle.Size = UDim2.new(0, 180, 0, 40)
toggle.Position = UDim2.new(0, 10, 0, 10)
toggle.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
toggle.Text = "MANUAL SPAM: OFF"
toggle.TextColor3 = Color3.fromRGB(255,255,255)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 13 

Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6) 

local function update()
    toggle.Text = spamEnabled and "MANUAL SPAM: ON" or "MANUAL SPAM: OFF"
    toggle.BackgroundColor3 = spamEnabled and Color3.fromRGB(60,160,60)
        or Color3.fromRGB(35,35,35)
end 

toggle.MouseButton1Click:Connect(function()
    spamEnabled = not spamEnabled
    update()
end) 

update()
