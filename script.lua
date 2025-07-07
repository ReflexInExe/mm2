-- MM2 Tools: Shoot Murderer, Kill All (Knife), Grab Gun + Toggle Visibility

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local maps = {"Bank2", "BioLab", "Factory", "Hospital3", "Hotel", "House2", "Mansion2", "MilBase", "Office3", "PoliceStation", "ResearchFacility", "Workplace"}

local highlights = {} -- Player highlights
local gunESPInstances = {} -- Gun ESP objects
local MAX_DISTANCE = 2000

local shootOffset = 2.8
local offsetToPingMult = 1

-- GUI
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "Reflex Hub"
gui.ResetOnSpawn = false

-- Format function
local function secondsToMinutes(seconds)
	if seconds == -1 then return "" end
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60
	return string.format("%d:%02d", minutes, remainingSeconds)
end

-- Create Timer Label
local roundTimerLabel = Instance.new("TextLabel")
roundTimerLabel.Name = "RoundTimer"
roundTimerLabel.Size = UDim2.new(0, 160, 0, 40)
roundTimerLabel.Position = UDim2.new(0.5, -80, 0, 10)
roundTimerLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
roundTimerLabel.BackgroundTransparency = 0.3
roundTimerLabel.TextColor3 = Color3.new(1, 1, 1)
roundTimerLabel.Font = Enum.Font.GothamBold
roundTimerLabel.TextScaled = true
roundTimerLabel.Text = ""
roundTimerLabel.Visible = false
roundTimerLabel.ZIndex = 2
roundTimerLabel.Parent = gui
Instance.new("UICorner", roundTimerLabel)

-- Timer Update Loop
task.spawn(function()
	while true do
		pcall(function()
			local timeLeft = ReplicatedStorage.Remotes.Extras.GetTimer:InvokeServer()
			if timeLeft and timeLeft > -1 then
				roundTimerLabel.Visible = true
				roundTimerLabel.Text = secondsToMinutes(timeLeft)
			else
				roundTimerLabel.Visible = false
			end
		end)
		task.wait(1)
	end
end)

-- OPTIONAL: Add a toggle button to show/hide the timer
-- Format function
local function secondsToMinutes(seconds)
	if seconds == -1 then return "" end
	local minutes = math.floor(seconds / 60)
	local remainingSeconds = seconds % 60
	return string.format("%d:%02d", minutes, remainingSeconds)
end

-- Create Timer Label

-- Timer Update Loop
task.spawn(function()
	while true do
		pcall(function()
			local timeLeft = ReplicatedStorage.Remotes.Extras.GetTimer:InvokeServer()
			if timeLeft and timeLeft > -1 then
				roundTimerLabel.Visible = true
				roundTimerLabel.Text = secondsToMinutes(timeLeft)
			else
				roundTimerLabel.Visible = false
			end
		end)
		task.wait(1)
	end
end)

-- OPTIONAL: Add a toggle button to show/hide the timer

-- Buttons

-- Helper to create a button
local function createButton(name, text, yPosition)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0, 160, 0, 40)
    button.Position = UDim2.new(1, -170, 0, yPosition)
    button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextScaled = true
    button.Text = text
    button.Parent = gui
    Instance.new("UICorner", button)
    return button
end

local shootBtn = createButton("ShootMurderer", "Shoot Murderer", 60)
local killAllBtn = createButton("KillAllKnife", "Kill All (Knife)", 110)
local grabGunBtn = createButton("GrabGun", "Grab Gun", 160)

-- Toggle Button (≡ small icon)
local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleVisibility"
toggleBtn.Size = UDim2.new(0, 30, 0, 30)
toggleBtn.Position = UDim2.new(1, -40, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.Text = "≡"
toggleBtn.TextScaled = true
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = gui
Instance.new("UICorner", toggleBtn)

-- Toggle Visibility Logic
local buttonsVisible = true
toggleBtn.MouseButton1Click:Connect(function()
    buttonsVisible = not buttonsVisible
    shootBtn.Visible = buttonsVisible
    killAllBtn.Visible = buttonsVisible
    grabGunBtn.Visible = buttonsVisible
end)

-- Helper Functions
local function getHRP(plr)
    return plr.Character and (plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:FindFirstChild("UpperTorso"))
end

local function getHumanoid(plr)
    return plr.Character and plr.Character:FindFirstChild("Humanoid")
end

local function getMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer and (plr.Backpack:FindFirstChild("Knife") or (plr.Character and plr.Character:FindFirstChild("Knife"))) then
            return plr
        end
    end
end

local function getPredictedPosition(target)
    local hrp = getHRP(target)
    local hum = getHumanoid(target)
    if not hrp or not hum then return Vector3.zero end

    local velocity = hrp.AssemblyLinearVelocity
    local moveDir = hum.MoveDirection
    local predicted = hrp.Position + (velocity * Vector3.new(0, 0.5, 0)) * (shootOffset / 15) + moveDir * shootOffset
    predicted *= (((localPlayer:GetNetworkPing() * 1000) * ((offsetToPingMult - 1) * 0.01)) + 1)
    return predicted
end

-- 🔫 Shoot Murderer Logic
shootBtn.MouseButton1Click:Connect(function()
    local hasGun = localPlayer.Backpack:FindFirstChild("Gun") or (localPlayer.Character and localPlayer.Character:FindFirstChild("Gun"))
    if not hasGun then
        warn("You are not the sheriff/hero or don't have a gun.")
        return
    end

    local murderer = getMurderer()
    if not murderer then
        warn("No murderer found.")
        return
    end

    -- Equip Gun
    if localPlayer.Backpack:FindFirstChild("Gun") then
        local hum = getHumanoid(localPlayer)
        if hum then hum:EquipTool(localPlayer.Backpack:FindFirstChild("Gun")) end
    end

    local predicted = getPredictedPosition(murderer)

    local args = {
        [1] = 1,
        [2] = predicted,
        [3] = "AH2"
    }

    local gunScript = localPlayer.Character and localPlayer.Character:FindFirstChild("Gun") and localPlayer.Character.Gun:FindFirstChild("KnifeLocal")
    if gunScript and gunScript:FindFirstChild("CreateBeam") then
        gunScript.CreateBeam.RemoteFunction:InvokeServer(unpack(args))
    else
        warn("Gun script missing CreateBeam.")
    end
end)

-- 🔪 Kill All With Knife (YARHM Logic)
killAllBtn.MouseButton1Click:Connect(function()
    local knifeTool = localPlayer.Backpack:FindFirstChild("Knife") or (localPlayer.Character and localPlayer.Character:FindFirstChild("Knife"))
    if not knifeTool then
        warn("You are not the murderer or do not have the knife.")
        return
    end

    -- Equip Knife
    if localPlayer.Backpack:FindFirstChild("Knife") then
        local hum = getHumanoid(localPlayer)
        if hum then hum:EquipTool(localPlayer.Backpack:FindFirstChild("Knife")) end
    end

    local knife = localPlayer.Character and localPlayer.Character:FindFirstChild("Knife")
    if not knife then
        warn("Knife not equipped.")
        return
    end

    -- Anchor and teleport players in front of you
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and getHRP(player) and getHumanoid(player) and getHumanoid(player).Health > 0 then
            local hrp = getHRP(player)
            local myhrp = getHRP(localPlayer)
            if hrp and myhrp then
                hrp.Anchored = true
                hrp.CFrame = myhrp.CFrame + myhrp.CFrame.LookVector * 1
            end
        end
    end

    -- Fire Stab Remote
    local args = { [1] = "Slash" }
    knife.Stab:FireServer(unpack(args))
    
    -- Unanchor players after stabbing
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and getHRP(player) then
            local hrp = getHRP(player)
            if hrp then
                hrp.Anchored = false
            end
        end
    end
end)

-- Improved addESP function with proper parenting
local function addESP(target, color)
    if not target or not target.Parent then return end
    
    -- Remove old highlight if exists
    if highlights[target] then
        highlights[target]:Destroy()
        highlights[target] = nil
    end
    
    -- Create new highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.FillColor = color
    highlight.OutlineColor = Color3.new(0,0,0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = target
    highlight.Parent = target
    highlight.Enabled = true
    
    highlights[target] = highlight
    
    -- Distance tracking
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not target or not target.Parent or not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
            if conn then conn:Disconnect() end
            return
        end
        
        local hrp = localPlayer.Character.HumanoidRootPart
        local targetHrp = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("UpperTorso") or target
        
        if targetHrp then
            local distance = (hrp.Position - targetHrp.Position).Magnitude
            highlight.Enabled = distance <= MAX_DISTANCE
        end
    end)
end

-- Enhanced role detection
local function getRole(plr)
    if not plr.Character then return "Innocent" end
    
    -- Check for Murderer (Knife)
    local function hasKnife()
        -- Check backpack
        if plr.Backpack and plr.Backpack:FindFirstChild("Knife") then
            return true
        end
        -- Check character
        if plr.Character:FindFirstChild("Knife") then
            return true
        end
        -- Check equipped tools
        local tool = plr.Character:FindFirstChildWhichIsA("Tool")
        if tool and tool:FindFirstChild("Slash") then
            return true
        end
        return false
    end
    
    -- Check for Sheriff (Gun)
    local function hasGun()
        -- Check backpack
        if plr.Backpack and plr.Backpack:FindFirstChild("Gun") then
            return true
        end
        -- Check character
        if plr.Character:FindFirstChild("Gun") then
            return true
        end
        -- Check equipped tools
        local tool = plr.Character:FindFirstChildWhichIsA("Tool")
        if tool and tool:FindFirstChild("Shoot") then
            return true
        end
        return false
    end
    
    if hasKnife() then return "Murderer" end
    if hasGun() then return "Sheriff" end
    return "Innocent"
end

-- Gun ESP system
local function updateGunESP()
    -- Clean up old instances
    for _, esp in pairs(gunESPInstances) do
        if esp and esp.Parent then
            esp:Destroy()
        end
    end
    gunESPInstances = {}
    
    -- Search all maps
    for _, mapName in ipairs(maps) do
        local mapFolder = workspace:FindFirstChild(mapName)
        if mapFolder then
            local gunDrop = mapFolder:FindFirstChild("GunDrop")
            if gunDrop and gunDrop:IsA("BasePart") then
                -- Create highlight
                local highlight = Instance.new("Highlight")
                highlight.Name = "GunHighlight"
                highlight.FillColor = Color3.fromRGB(170, 0, 255)
                highlight.OutlineColor = Color3.new(1,1,1)
                highlight.FillTransparency = 0.3
                highlight.OutlineTransparency = 0
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                highlight.Adornee = gunDrop
                highlight.Parent = gunDrop
                
                -- Create billboard
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "GunESP"
                billboard.Adornee = gunDrop
                billboard.Size = UDim2.new(5, 0, 1.5, 0)
                billboard.StudsOffset = Vector3.new(0, 3, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = gunDrop
                
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = "🔫 GUN DROP"
                label.TextColor3 = Color3.fromRGB(255, 100, 255)
                label.TextScaled = true
                label.Font = Enum.Font.GothamBlack
                label.TextStrokeTransparency = 0
                label.TextStrokeColor3 = Color3.new(0,0,0)
                label.Parent = billboard
                
                -- Store instances
                table.insert(gunESPInstances, highlight)
                table.insert(gunESPInstances, billboard)
                
                -- Distance tracking
                local conn
                conn = RunService.Heartbeat:Connect(function()
                    if not gunDrop or not gunDrop.Parent or not localPlayer.Character or not localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        if conn then conn:Disconnect() end
                        return
                    end
                    
                    local distance = (localPlayer.Character.HumanoidRootPart.Position - gunDrop.Position).Magnitude
                    highlight.Enabled = distance <= MAX_DISTANCE
                    billboard.Enabled = distance <= MAX_DISTANCE
                end)
            end
        end
    end
end

-- Main ESP update function
local function updateAllESP()
    -- Update player ESP
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer and plr.Character then
            local role = getRole(plr)
            local color = Color3.fromRGB(0, 255, 0) -- Innocent
            
            if role == "Murderer" then
                color = Color3.fromRGB(255, 0, 0)
            elseif role == "Sheriff" then
                color = Color3.fromRGB(0, 0, 255)
            end
            
            if highlights[plr.Character] then
                highlights[plr.Character].FillColor = color
            else
                addESP(plr.Character, color)
            end
        end
    end
    
    -- Update gun ESP
    pcall(updateGunESP)
end

-- Initialize ESP system
local function initESP()
    -- Initial update
    updateAllESP()
    
    -- Set up event listeners
    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function(char)
            task.wait(1) -- Wait for character to load
            updateAllESP()
        end)
    end)
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= localPlayer then
            if plr.Character then
                updateAllESP()
            end
            plr.CharacterAdded:Connect(function(char)
                task.wait(1)
                updateAllESP()
            end)
        end
    end
    
    -- Weapon tracking
    local function trackWeapons(plr)
        if plr == localPlayer then return end
        
        if plr.Backpack then
            plr.Backpack.ChildAdded:Connect(function()
                task.wait(0.5)
                updateAllESP()
            end)
            plr.Backpack.ChildRemoved:Connect(function()
                task.wait(0.5)
                updateAllESP()
            end)
        end
        
        plr.CharacterAdded:Connect(function(char)
            if char:WaitForChild("Backpack", 2) then
                char.Backpack.ChildAdded:Connect(function()
                    task.wait(0.5)
                    updateAllESP()
                end)
                char.Backpack.ChildRemoved:Connect(function()
                    task.wait(0.5)
                    updateAllESP()
                end)
            end
            
            char.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then
                    task.wait(0.1)
                    updateAllESP()
                end
            end)
        end)
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        trackWeapons(plr)
    end
    Players.PlayerAdded:Connect(trackWeapons)
    
    -- Main update loop
    while true do
        pcall(updateAllESP)
        task.wait(2)
    end
end

-- Start the ESP system
task.spawn(initESP)

grabGunBtn.MouseButton1Click:Connect(function()
    local hrp = getHRP(localPlayer)
    if not hrp then
        warn("HumanoidRootPart not found")
        return
    end
    
    local foundGun = false
    
    -- Search all maps for gun drops
    for _, mapName in ipairs(maps) do
        local mapFolder = workspace:FindFirstChild(mapName)
        if mapFolder then
            local gunDrop = mapFolder:FindFirstChild("GunDrop")
            if gunDrop and gunDrop:IsA("BasePart") then
                foundGun = true
                
                -- Fire touch events sequence (most reliable order)
                for i = 1, 5 do  -- Multiple attempts for reliability
                    firetouchinterest(gunDrop, hrp, 1) -- Touch begin
                    task.wait(0.05)
                    firetouchinterest(gunDrop, hrp, 0) -- Touch end
                    task.wait(0.05)
                end
                
                warn("Triggered TouchInterest on gun in "..mapName)
                return
            end
        end
    end
    
    if not foundGun then
        warn("No GunDrop found in any map")
    end
end)
