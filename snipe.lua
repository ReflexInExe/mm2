local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

-- GUI Setup
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "ShootSpecificPlayer"
gui.ResetOnSpawn = false

-- Username TextBox
local inputBox = Instance.new("TextBox")
inputBox.Size = UDim2.new(0, 160, 0, 40)
inputBox.Position = UDim2.new(1, -170, 0, 10)  -- Positioning to the right
inputBox.PlaceholderText = "Enter username"
inputBox.Text = ""
inputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
inputBox.TextColor3 = Color3.new(1, 1, 1)
inputBox.Font = Enum.Font.GothamBold
inputBox.TextScaled = true
inputBox.Parent = gui
Instance.new("UICorner", inputBox)

-- Shoot Button
local shootBtn = Instance.new("TextButton")
shootBtn.Size = UDim2.new(0, 160, 0, 40)
shootBtn.Position = UDim2.new(1, -170, 0, 60)  -- Positioning to the right
shootBtn.Text = "Shoot Player"
shootBtn.BackgroundColor3 = Color3.fromRGB(70, 0, 0)
shootBtn.TextColor3 = Color3.new(1, 1, 1)
shootBtn.Font = Enum.Font.GothamBold
shootBtn.TextScaled = true
shootBtn.Parent = gui
Instance.new("UICorner", shootBtn)

-- ESP Function to create BillboardGui above player's head
local function addESP(target)
    if not target or not target.Parent then return end

    -- Remove old BillboardGui if it exists
    if target:FindFirstChild("ESP_Billboard") then
        target.ESP_Billboard:Destroy()
    end

    -- Create new BillboardGui for the ESP
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Adornee = target:FindFirstChild("Head")  -- Attach to the player's head
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)  -- Position above the head
    billboard.AlwaysOnTop = true
    billboard.Parent = target

    -- Create label inside the BillboardGui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = target.Name
    label.TextColor3 = Color3.fromRGB(169, 169, 169)  -- Grey text
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = billboard
end

-- Add ESP for all players
local function updateAllESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            addESP(plr.Character)
        end
    end
end

-- Initialize ESP for players that are already in the game
updateAllESP()

-- Watch for new players joining the game and add ESP
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        if char:FindFirstChild("Head") then
            addESP(char)
        end
    end)
end)

-- Helper Functions for shooting
local function getHRP(plr)
    return plr.Character and (plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("UpperTorso"))
end

local function getHumanoid(plr)
    return plr.Character and plr.Character:FindFirstChild("Humanoid")
end

local function getPredictedPosition(target)
    local hrp = getHRP(target)
    local hum = getHumanoid(target)
    if not hrp or not hum then return Vector3.zero end

    local shootOffset = 2.8
    local offsetToPingMult = 1
    local velocity = hrp.AssemblyLinearVelocity
    local moveDir = hum.MoveDirection

    local predicted = hrp.Position + (velocity * Vector3.new(0, 0.5, 0)) * (shootOffset / 15) + moveDir * shootOffset
    predicted *= (((localPlayer:GetNetworkPing() * 1000) * ((offsetToPingMult - 1) * 0.01)) + 1)
    return predicted
end

-- Shoot Button Logic
shootBtn.MouseButton1Click:Connect(function()
    local targetName = inputBox.Text
    local target = Players:FindFirstChild(targetName)
    if not target then
        warn("Player not found")
        return
    end

    local hasGun = localPlayer.Backpack:FindFirstChild("Gun") or (localPlayer.Character and localPlayer.Character:FindFirstChild("Gun"))
    if not hasGun then
        warn("You do not have a gun.")
        return
    end

    -- Equip gun if in backpack
    if localPlayer.Backpack:FindFirstChild("Gun") then
        local hum = getHumanoid(localPlayer)
        if hum then hum:EquipTool(localPlayer.Backpack:FindFirstChild("Gun")) end
    end

    local predicted = getPredictedPosition(target)

    local args = {
        [1] = 1,
        [2] = predicted,
        [3] = "AH2"
    }

    local gunScript = localPlayer.Character and localPlayer.Character:FindFirstChild("Gun") and localPlayer.Character.Gun:FindFirstChild("KnifeLocal")
    if gunScript and gunScript:FindFirstChild("CreateBeam") then
        gunScript.CreateBeam.RemoteFunction:InvokeServer(unpack(args))
    else
        warn("Gun script or CreateBeam function not found.")
    end
end)
