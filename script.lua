-- MM2 Tools: Shoot Murderer, Kill All (Knife), Grab Gun + Toggle Visibility

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local highlights = {}

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

-- 🔫 Grab Gun Button (using firetouchinterest instead of teleport)
grabGunBtn.MouseButton1Click:Connect(function()
	for _, obj in pairs(workspace:GetChildren()) do
		if obj:IsA("Tool") and obj.Name == "GunDrop" and obj:FindFirstChild("Handle") then
			local hrp = getHRP(localplayer)
			if hrp then
				firetouchinterest(obj.Handle, hrp, 0)
				task.wait(0.1)
				firetouchinterest(obj.Handle, hrp, 1)
			end
		end
	end
end)

local function addESP(target)
	if not target or target:FindFirstChild("ESP_Highlight") then return end
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Highlight"
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 1
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = target
	highlight.Parent = target
	highlights[target] = highlight
	return highlight
end

local function removeAllESP()
	for target, highlight in pairs(highlights) do
		if highlight and highlight.Parent then
			highlight:Destroy()
		end
		highlights[target] = nil
	end
end

local function findMurderer()
	for _, plr in ipairs(Players:GetPlayers()) do
		if (plr.Backpack and plr.Backpack:FindFirstChild("Knife")) or (plr.Character and plr.Character:FindFirstChild("Knife")) then
			return plr
		end
	end
	return nil
end

local function findSheriff()
	for _, plr in ipairs(Players:GetPlayers()) do
		if (plr.Backpack and plr.Backpack:FindFirstChild("Gun")) or (plr.Character and plr.Character:FindFirstChild("Gun")) then
			if plr ~= findMurderer() then
				return plr
			end
		end
	end
	return nil
end

local function updateESP()
	local murderer = findMurderer()
	local sheriff = findSheriff()

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			local highlight = highlights[plr.Character] or addESP(plr.Character)
			if not highlight then
				continue
			end

			if plr == murderer then
				highlight.FillColor = Color3.fromRGB(255, 0, 0) -- Red for murderer
			elseif plr == sheriff then
				highlight.FillColor = Color3.fromRGB(0, 0, 255) -- Blue for sheriff
			else
				highlight.FillColor = Color3.fromRGB(0, 255, 0) -- Green for innocent
			end
		end
	end

	local drop = workspace:FindFirstChild("GunDrop")
	if drop and drop:IsA("Tool") and drop:FindFirstChild("Handle") then
		local highlight = highlights[drop] or addESP(drop)
		if highlight then
			highlight.FillColor = Color3.fromRGB(150, 0, 255) -- Purple
		end
	end
end

while true do
	pcall(updateESP)
	task.wait(0.5)
end

Players.PlayerRemoving:Connect(function(plr)
	if plr.Character and highlights[plr.Character] then
		highlights[plr.Character]:Destroy()
		highlights[plr.Character] = nil
	end
end)
