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

-- ESP Function to create highlight around player's hitbox (HumanoidRootPart)
local function addESP(target)
    if not target or not target.Parent then return end
    
    -- Find the HumanoidRootPart or UpperTorso for hitbox
    local hrp = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("UpperTorso")
    if not hrp then return end

    -- Remove old Highlight if it exists
    if target:FindFirstChild("ESP_Highlight") then
        target.ESP_Highlight:Destroy()
    end

    -- Create new Highlight for the hitbox (HumanoidRootPart or UpperTorso)
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = Color3.fromRGB(169, 169, 169)  -- Grey color for the hitbox
    highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = hrp
    highlight.Parent = target
    highlight.Enabled = true
end

-- Refresh ESP for all players continuously
local function updateAllESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character then
            addESP(plr.Character)
        end
    end
end

-- Update ESP at regular intervals using Heartbeat
RunService.Heartbeat:Connect(function()
    updateAllESP()  -- Refresh ESP every frame
end)

-- Watch for new players joining the game and add ESP
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        if char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") then
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
    local targetName = inputBox.Text:lower()  -- Convert input to lowercase
    local target = nil
    
    -- Search for a player with a matching name (case insensitive)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower() == targetName then  -- Compare lowercase versions
            target = plr
            break
        end
    end

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
