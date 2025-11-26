-- The Lost Front | БЕЗ UI АВТОСТАРТ | ESP + VIS CHECK + HEALTH BAR

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Активируем все функции по умолчанию (без UI)
local ESPEnabled = true
local VisCheckEnabled = true 
local HealthBarEnabled = true 
local Highlights = {} -- Хранит {Highlight, HealthBar, HealthFill}

-- ============================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==============================

-- Проверка на врага (ищет никнейм локального игрока над головой цели)
local function IsEnemy(plr)
    if not plr.Character or not plr.Character:FindFirstChild("Head") then return false end
    for _, v in pairs(plr.Character.Head:GetChildren()) do
        if (v:IsA("BillboardGui") or v:IsA("SurfaceGui")) then
            for _, t in pairs(v:GetChildren()) do
                if t:IsA("TextLabel") and t.Text == plr.Name then
                    return false
                end
            end
        end
    end
    return true
end

-- Проверка видимости (Raycasting)
local function IsVisible(targetCharacter)
    local localCharacter = LocalPlayer.Character
    local localHead = localCharacter and localCharacter:FindFirstChild("Head")
    local targetHead = targetCharacter:FindFirstChild("Head")
    
    if not localHead or not targetHead then return false end

    local startPos = localHead.Position
    local rayDirection = targetHead.Position - startPos
    
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {localCharacter, targetCharacter}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local raycastResult = Workspace:Raycast(startPos, rayDirection.unit * rayDirection.magnitude, rayParams)

    if raycastResult then
        return raycastResult.Instance.Parent == targetCharacter or raycastResult.Instance:IsDescendantOf(targetCharacter) 
    end
    
    return true
end

-- Обновление цвета ESP обводки
local function UpdateESPColor(plr)
    local highlightEntry = Highlights[plr]
    local highlight = highlightEntry and highlightEntry.Highlight
    
    if not highlight or not plr.Character then return end
    
    local isVisible = VisCheckEnabled and IsVisible(plr.Character)

    -- Белый для видимого, Красный для невидимого/скрытого
    highlight.OutlineColor = isVisible and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 0, 0)
end

-- Создание полосы здоровья
local function CreateHealthBar(plr)
    local character = plr.Character
    local head = character:FindFirstChild("Head")
    if not character or not head or not Highlights[plr] or Highlights[plr].HealthBar then return end
    
    local HealthBarGui = Instance.new("BillboardGui")
    HealthBarGui.Size = UDim2.new(0, 100, 0, 8) 
    HealthBarGui.StudsOffset = Vector3.new(-5.5, 1, 0) -- Смещение влево
    HealthBarGui.Adornee = head
    HealthBarGui.AlwaysOnTop = true
    HealthBarGui.ExtentsOffset = Vector3.new(0, 1.5, 0) 
    HealthBarGui.Parent = character
    
    local HealthBarBg = Instance.new("Frame")
    HealthBarBg.Size = UDim2.new(1, 0, 1, 0)
    HealthBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    HealthBarBg.Parent = HealthBarGui
    
    local HealthBarFill = Instance.new("Frame")
    HealthBarFill.Size = UDim2.new(1, 0, 1, 0)
    HealthBarFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0) 
    HealthBarFill.Parent = HealthBarBg
    
    Highlights[plr].HealthBar = HealthBarGui
    Highlights[plr].HealthFill = HealthBarFill
end

-- Обновление размера и цвета полосы здоровья
local function UpdateHealthBar(plr)
    local highlightEntry = Highlights[plr]
    if not highlightEntry or not highlightEntry.HealthBar or not highlightEntry.HealthFill or not plr.Character then return end
    
    local humanoid = plr.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local fillFrame = highlightEntry.HealthFill
    local ratio = humanoid.Health / humanoid.MaxHealth
    
    fillFrame.Size = UDim2.new(ratio, 0, 1, 0)
    
    -- Плавный переход цвета (зеленый -> красный)
    local r, g
    if ratio >= 0.5 then
        r = 2 * (1 - ratio) * 255
        g = 255
    else
        r = 255
        g = 2 * ratio * 255
    end
    
    fillFrame.BackgroundColor3 = Color3.fromRGB(r, g, 0)
end

-- ============================== ОСНОВНАЯ ЛОГИКА ==============================

-- Создание ESP-объектов
local function CreateESP(plr)
    if plr == LocalPlayer or Highlights[plr] then return end
    if not IsEnemy(plr) then return end
    if not plr.Character then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = plr.Character
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
    hl.Enabled = true -- Всегда включено при создании, управляется UpdateAll
    hl.Parent = plr.Character
    
    Highlights[plr] = {
        Highlight = hl,
        HealthBar = nil,
        HealthFill = nil
    }

    if VisCheckEnabled then UpdateESPColor(plr) end
    if HealthBarEnabled then CreateHealthBar(plr) end
end

-- Функция очистки и обновления
local function UpdateAll()
    local playersToCleanup = {}
    
    -- Очистка неактуальных
    for plr, hlEntry in pairs(Highlights) do 
        if not plr.Character or not IsEnemy(plr) or not ESPEnabled then 
            if hlEntry.Highlight and hlEntry.Highlight.Parent then pcall(function() hlEntry.Highlight:Destroy() end) end
            if hlEntry.HealthBar and hlEntry.HealthBar.Parent then pcall(function() hlEntry.HealthBar:Destroy() end) end
            table.insert(playersToCleanup, plr)
        end
    end
    for _, plr in ipairs(playersToCleanup) do
        Highlights[plr] = nil
    end
    
    -- Создание
    if ESPEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and IsEnemy(plr) then 
                if not Highlights[plr] then
                    CreateESP(plr)
                end
            end
        end
    end
end

-- Обработчики событий
Players.PlayerAdded:Connect(function(p) 
    p.CharacterAdded:Connect(function() 
        task.wait(2) 
        if ESPEnabled then CreateESP(p) end 
    end) 
end)

LocalPlayer.CharacterAdded:Connect(function() task.wait(2) UpdateAll() end)

-- Быстрый цикл для проверки видимости и обновления Health Bar
RunService.RenderStepped:Connect(function()
    if ESPEnabled then
        for plr, hlEntry in pairs(Highlights) do
            if plr.Character then 
                -- Обновление Health Bar
                if HealthBarEnabled and hlEntry.HealthBar then
                    UpdateHealthBar(plr)
                end
                
                -- Обновление ESP цвета
                if VisCheckEnabled and hlEntry.Highlight then
                    UpdateESPColor(plr)
                end
            end
        end
    end
end)

-- Периодическая проверка для ловли новых игроков
task.spawn(function()
    while task.wait(5) do 
        if ESPEnabled then UpdateAll() end 
    end
end)

-- Автостарт
task.wait(1)
UpdateAll()

print("The Lost Front ESP Activated (Vis Check + Health Bar)!")
