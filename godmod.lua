-- God Mode Standalone with Jump Fix
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

if not localPlayer then
    warn("Player not found!")
    return
end

local function enableEnhancedGodMode()
    -- Wait for character
    if not localPlayer.Character then
        localPlayer.CharacterAdded:Wait()
    end
    
    local character = localPlayer.Character
    local humanoid = character:WaitForChild("Humanoid")
    local camera = workspace.CurrentCamera
    
    -- Save original state
    local originalCFrame = camera.CFrame
    
    -- Create new enhanced humanoid
    local newHumanoid = humanoid:Clone()
    
    -- Configure god properties (keep jumping enabled)
    newHumanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)      -- No death
    newHumanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) -- No falling
    newHumanoid.BreakJointsOnDeath = false
    newHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    
    -- IMPORTANT: Allow physics and jumping
    newHumanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
    newHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    newHumanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
    
    -- Health management
    newHumanoid.Health = newHumanoid.MaxHealth
    
    -- Smooth transition
    localPlayer.Character = nil
    newHumanoid.Parent = character
    
    -- Delay destruction of old humanoid
    task.delay(0.2, function()
        if humanoid and humanoid.Parent then
            humanoid:Destroy()
        end
    end)
    
    -- Restore character and camera
    localPlayer.Character = character
    camera.CameraSubject = newHumanoid
    camera.CFrame = originalCFrame
    
    -- Handle animations
    local animateScript = character:FindFirstChild("Animate")
    if animateScript then
        animateScript.Disabled = true
        task.wait(0.1)
        animateScript.Disabled = false
    end
    
    -- Continuous protection system
    local healthConnection
    healthConnection = newHumanoid.HealthChanged:Connect(function()
        if newHumanoid.Health < newHumanoid.MaxHealth then
            newHumanoid.Health = newHumanoid.MaxHealth
        end
    end)
    
    -- Jump power watcher (ensures jump stays enabled)
    local jumpConnection
    jumpConnection = RunService.Heartbeat:Connect(function()
        if newHumanoid:GetState() == Enum.HumanoidStateType.Jumping then
            newHumanoid.JumpPower = 50 -- Standard jump power
            newHumanoid.Jump = true
        end
    end)
    
    -- Auto-repair system
    local characterAddedConnection
    characterAddedConnection = localPlayer.CharacterAdded:Connect(function(newChar)
        -- Cleanup old connections
        if healthConnection then healthConnection:Disconnect() end
        if jumpConnection then jumpConnection:Disconnect() end
        if characterAddedConnection then characterAddedConnection:Disconnect() end
        
        -- Re-enable god mode on respawn
        task.wait(1) -- Wait for character to fully load
        enableEnhancedGodMode()
    end)
    
    print("Enhanced God Mode activated - Jumping enabled")
end

-- Toggle system with UI feedback
local godModeEnabled = true
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local notification = Instance.new("TextLabel")
notification.Size = UDim2.new(0, 200, 0, 50)
notification.Position = UDim2.new(0.5, -100, 0.1, 0)
notification.AnchorPoint = Vector2.new(0.5, 0)
notification.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
notification.TextColor3 = Color3.new(1, 1, 1)
notification.Text = "God Mode: ON (Press G to toggle)"
notification.Visible = false
notification.Parent = screenGui

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.G then
        godModeEnabled = not godModeEnabled
        
        if godModeEnabled then
            enableEnhancedGodMode()
            notification.Text = "God Mode: ON (Press G to toggle)"
            notification.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        else
            localPlayer.Character:BreakJoints()
            notification.Text = "God Mode: OFF (Press G to toggle)"
            notification.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        end
        
        notification.Visible = true
        task.delay(3, function()
            notification.Visible = false
        end)
    end
end)

-- Initial activation
enableEnhancedGodMode()
