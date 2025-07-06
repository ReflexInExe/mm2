-- MM2 Tools: Shoot Murderer, Kill All (Knife), Grab Gun + Toggle Visibility

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local maps = {"Bank 2", "Bio Lab", "Factory", "Hospital 3", "Hotel 2", "House 2", "Mansion 2", "Mil-Base", "Office 3", "Police Station", "Research Facility", "Workplace"}

local highlights = {}
local gunDropParts = {}

local localplayer = Players.LocalPlayer
local shootOffset = 2.8
local offsetToPingMult = 1

-- GUI
local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
gui.Name = "MM2Tools"
gui.ResetOnSpawn = false

local function createButton(name, text, yOffset)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 150, 0, 40)
	btn.Position = UDim2.new(1, -170, 0, yOffset)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.Text = text
	btn.Parent = gui
	Instance.new("UICorner", btn)
	return btn
end

-- Buttons
local shootBtn = createButton("ShootMurderer", "Shoot Murderer", 100)
local killAllBtn = createButton("KillAllKnife", "Kill All (Knife)", 150)
local grabGunBtn = createButton("GrabGun", "Grab Gun", 200)

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
		if plr ~= localplayer and (plr.Backpack:FindFirstChild("Knife") or (plr.Character and plr.Character:FindFirstChild("Knife"))) then
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
	predicted *= (((localplayer:GetNetworkPing() * 1000) * ((offsetToPingMult - 1) * 0.01)) + 1)
	return predicted
end

-- 🔫 Shoot Murderer Logic
shootBtn.MouseButton1Click:Connect(function()
	local hasGun = localplayer.Backpack:FindFirstChild("Gun") or (localplayer.Character and localplayer.Character:FindFirstChild("Gun"))
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
	if localplayer.Backpack:FindFirstChild("Gun") then
		local hum = getHumanoid(localplayer)
		if hum then hum:EquipTool(localplayer.Backpack:FindFirstChild("Gun")) end
	end

	local predicted = getPredictedPosition(murderer)

	local args = {
		[1] = 1,
		[2] = predicted,
		[3] = "AH2"
	}

	local gunScript = localplayer.Character and localplayer.Character:FindFirstChild("Gun") and localplayer.Character.Gun:FindFirstChild("KnifeLocal")
	if gunScript and gunScript:FindFirstChild("CreateBeam") then
		gunScript.CreateBeam.RemoteFunction:InvokeServer(unpack(args))
	else
		warn("Gun script missing CreateBeam.")
	end
end)

-- 🔪 Kill All With Knife (YARHM Logic)
killAllBtn.MouseButton1Click:Connect(function()
	local knifeTool = localplayer.Backpack:FindFirstChild("Knife") or (localplayer.Character and localplayer.Character:FindFirstChild("Knife"))
	if not knifeTool then
		warn("You are not the murderer or do not have the knife.")
		return
	end

	-- Equip Knife
	if localplayer.Backpack:FindFirstChild("Knife") then
		local hum = getHumanoid(localplayer)
		if hum then hum:EquipTool(localplayer.Backpack:FindFirstChild("Knife")) end
	end

	local knife = localplayer.Character and localplayer.Character:FindFirstChild("Knife")
	if not knife then
		warn("Knife not equipped.")
		return
	end

	-- Anchor and teleport players in front of you
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localplayer and player.Character and getHRP(player) and getHumanoid(player) and getHumanoid(player).Health > 0 then
			local hrp = getHRP(player)
			local myhrp = getHRP(localplayer)
			if hrp and myhrp then
				hrp.Anchored = true
				hrp.CFrame = myhrp.CFrame + myhrp.CFrame.LookVector * 1
			end
		end
	end

	-- Fire Stab Remote
	local args = { [1] = "Slash" }
	knife.Stab:FireServer(unpack(args))
end)

grabGunBtn.MouseButton1Click:Connect(function()
    local hrp = getHRP(localplayer)
    if not hrp then return end

    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Tool") and obj.Name == "GunDrop" and obj:FindFirstChild("Handle") then
            local originalPos = hrp.CFrame

            -- Teleport to gun handle
            hrp.CFrame = obj.Handle.CFrame + Vector3.new(0, 3, 0)  -- a bit above the gun handle

            task.wait(0.1)  -- small wait to ensure position update

            -- Fire touch events to grab
            firetouchinterest(obj.Handle, hrp, 0)
            task.wait(0.1)
            firetouchinterest(obj.Handle, hrp, 1)

            task.wait(0.1)  -- wait for pickup to register

            -- Teleport back
            hrp.CFrame = originalPos
            break  -- exit after grabbing the first gun
        end
    end
end)

local function addESP(target, color)
	if not target or target:FindFirstChild("ESP_Highlight") then return end
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = color
	highlight.Adornee = target
	highlight.Parent = target
	highlights[target] = highlight
	return highlight
end

local function getRole(plr)
	if not plr.Character then return "Innocent" end
	if (plr.Backpack and plr.Backpack:FindFirstChild("Knife")) or (plr.Character and plr.Character:FindFirstChild("Knife")) then
		return "Murderer"
	end
	if (plr.Backpack and plr.Backpack:FindFirstChild("Gun")) or (plr.Character and plr.Character:FindFirstChild("Gun")) then
		return "Sheriff"
	end
	return "Innocent"
end

local function updateESP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			local role = getRole(plr)
			local color
			if role == "Murderer" then
				color = Color3.fromRGB(255, 0, 0)
			elseif role == "Sheriff" then
				color = Color3.fromRGB(0, 0, 255)
			else
				color = Color3.fromRGB(0, 255, 0)
			end
			addESP(plr.Character, color)
		end
	end

	for _, mapName in ipairs(maps) do
	local mapFolder = workspace:FindFirstChild(mapName)
	if mapFolder then
		local gunDrop = mapFolder:FindFirstChild("GunDrop")
		if gunDrop and gunDrop:IsA("BasePart") and not gunDrop:FindFirstChild("GunESP") then
			-- Create BillboardGui
			local billboard = Instance.new("BillboardGui")
			billboard.Name = "GunESP"
			billboard.Adornee = gunDrop
			billboard.Size = UDim2.new(0, 100, 0, 40)
			billboard.StudsOffset = Vector3.new(0, 2.5, 0)
			billboard.AlwaysOnTop = true
			billboard.Parent = gunDrop

			-- Create TextLabel
			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = "🔫 Gun"
			label.TextColor3 = Color3.fromRGB(170, 0, 255)
			label.TextScaled = true
			label.Font = Enum.Font.GothamBold
			label.Parent = billboard
		end
	end
end

Players.PlayerRemoving:Connect(function(plr)
	if plr.Character and highlights[plr.Character] then
		highlights[plr.Character]:Destroy()
		highlights[plr.Character] = nil
	end
end)

task.spawn(function()
	while true do
		pcall(updateESP)
		task.wait(0.5)
	end
end)

grabGunBtn.MouseButton1Click:Connect(function()
    local hrp = getHRP(localplayer)
    if not hrp then return end

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj.Name == "GunDrop" and obj:FindFirstChild("Handle") then
            local originalCFrame = hrp.CFrame
            local handle = obj.Handle

            -- Teleport to gun
            hrp.CFrame = handle.CFrame + Vector3.new(0, 3, 0)
            task.wait(0.1)

            if typeof(firetouchinterest) == "function" then
                firetouchinterest(handle, hrp, 0)
                task.wait(0.1)
                firetouchinterest(handle, hrp, 1)
            else
                warn("firetouchinterest is not available.")
            end

            task.wait(0.1)
            hrp.CFrame = originalCFrame
            break
        end
    end
end)
