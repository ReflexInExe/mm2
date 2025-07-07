table.insert(module, {
    Type = "Button",
    Args = {"God Mode (Stable Version)", function(Self)
        -- Vérification des prérequis
        if not localplayer or not localplayer.Character then
            warn("Player character not found!")
            return
        end

        local Char = localplayer.Character
        local Human = Char:FindFirstChildOfClass("Humanoid")
        
        if not Human then
            warn("Humanoid not found in character!")
            return
        end

        -- Sauvegarde de la position et état actuels
        local Cam = workspace.CurrentCamera
        local originalCFrame = Cam.CFrame
        local originalHealth = Human.Health

        -- Création d'un nouveau Humanoid avec propriétés modifiées
        local newHuman = Human:Clone()
        
        -- Configuration du nouveau Humanoid
        newHuman:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        newHuman:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        newHuman:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        newHuman.BreakJointsOnDeath = false
        newHuman.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        newHuman.Health = newHuman.MaxHealth

        -- Transition en douceur
        localplayer.Character = nil
        newHuman.Parent = Char
        
        -- Suppression de l'ancien Humanoid après un court délai
        delay(0.1, function()
            if Human and Human.Parent then
                Human:Destroy()
            end
        end)

        -- Restauration de la caméra et du personnage
        localplayer.Character = Char
        Cam.CameraSubject = newHuman
        Cam.CFrame = originalCFrame

        -- Gestion des animations
        local animateScript = Char:FindFirstChild("Animate")
        if animateScript then
            animateScript.Disabled = true
            task.wait(0.1)
            animateScript.Disabled = false
        end

        -- Protection continue
        local healthConnection
        healthConnection = newHuman.HealthChanged:Connect(function()
            if newHuman.Health < newHuman.MaxHealth then
                newHuman.Health = newHuman.MaxHealth
            end
        end)

        -- Nettoyage lorsque le personnage est réinitialisé
        local characterAddedConnection
        characterAddedConnection = localplayer.CharacterAdded:Connect(function(newChar)
            if healthConnection then
                healthConnection:Disconnect()
            end
            if characterAddedConnection then
                characterAddedConnection:Disconnect()
            end
        end)

        -- Message de confirmation
        print("God Mode activated - More stable version")
    end}
})
