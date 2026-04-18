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
    if not targetPlayer then return end

    local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end

    for remote, args in pairs(revertedRemotes) do
        local targets = {}

        for k, v in pairs(args[5]) do
            if typeof(v) == "Vector3" then

                local dist = (v - targetRoot.Position).Magnitude

                if dist < 6 then
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
            task.wait(0.003)
        else
            task.wait(0.1)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.G then
        spamEnabled = not spamEnabled
        ToggleBtn.Text = spamEnabled and "SPAM: ON" or "SPAM: OFF"
    end
end)

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 220, 0, 120)
Frame.Position = UDim2.new(0, 20, 0, 100)
Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local UICorner = Instance.new("UICorner", Frame)
UICorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Parry UI"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16

local ToggleBtn = Instance.new("TextButton", Frame)
ToggleBtn.Position = UDim2.new(0, 10, 0, 40)
ToggleBtn.Size = UDim2.new(1, -20, 0, 40)
ToggleBtn.Text = "SPAM: OFF"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14

local BtnCorner = Instance.new("UICorner", ToggleBtn)
BtnCorner.CornerRadius = UDim.new(0, 8)

ToggleBtn.MouseButton1Click:Connect(function()
    spamEnabled = not spamEnabled
    ToggleBtn.Text = spamEnabled and "SPAM: ON" or "SPAM: OFF"
end)
