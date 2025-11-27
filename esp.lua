-- The Lost Front | АВТОСТАРТ | ESP + VIS CHECK + БЕЛЫЙ, ТОНКИЙ ВЕРТИКАЛЬНЫЙ HEALTH BAR С HP

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Активируем все функции по умолчанию (без UI)
local ESPEnabled = true
local VisCheckEnabled = true 
local HealthBarEnabled = true 
local Highlights = {} -- Хранит {Highlight, HealthBar, HealthFill, HealthText}

-- ============================== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==============================

local function IsEnemy(plr)
    if not plr.Character or not plr.Character:FindFirstChild("Head") then return false end
    for _, v in pairs(plr.Character.Head:GetChildren()) do
        if (v:IsA("BillboardGui") or v:IsA("SurfaceGui")) then
            for _, t in pairs(v:GetChildren()) do
                if t:IsA("TextLabel") and t.Text == plr.Name then return false end
            end
        end
    end
    return true
end

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

local function UpdateESPColor(plr)
    local highlightEntry = Highlights[plr]
    local highlight = highlightEntry and highlightEntry.Highlight
    if not highlight or not plr.Character then return end
    
    local isVisible = VisCheckEnabled and IsVisible(plr.Character)
    highlight.OutlineColor = isVisible and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 0, 0)
end

local function CreateHealthBar(plr)
    local character = plr.Character
    local rootPart = character:FindFirstChild("HumanoidRootPart") 
    if not character or not rootPart or not Highlights[plr] or Highlights[plr].HealthBar then return end
    
    -- 1. BillboardGui (Основной контейнер)
    local HealthBarGui = Instance.new("BillboardGui")
    HealthBarGui.Size = UDim2.new(0, 2, 0, 30) -- Уменьшаем: 2x30 пикселей
    HealthBarGui.StudsOffset = Vector3.new(-3.5, 2, 0) -- Немного дальше влево
    HealthBarGui.Adornee = rootPart 
    HealthBarGui.AlwaysOnTop = true
    HealthBarGui.Parent = character
    
    -- 2. Фон полосы (белый)
    local HealthBarBg = Instance.new("Frame")
    HealthBarBg.Size = UDim2.new(1, 0, 1, 0)
    HealthBarBg.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Белый фон
    HealthBarBg.BackgroundTransparency = 0.5 -- Полупрозрачный фон
    HealthBarBg.Parent = HealthBarGui
    
    -- 3. Заполнение (HP Fill) (тоже белый)
    local HealthBarFill = Instance.new("Frame")
    HealthBarFill.Size = UDim2.new(1, 0, 1, 0)
    HealthBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Белое заполнение
    HealthBarFill.AnchorPoint = Vector2.new(0, 1) -- Якорь снизу для заполнения вверх
    HealthBarFill.Position = UDim2.new(0, 0, 1, 0) -- Позиция внизу
    HealthBarFill.Parent = HealthBarBg
    
    -- 4. Текст HP (белый)
    local HealthText = Instance.new("TextLabel")
    HealthText.Text = "100" -- Будет только число HP
    HealthText.Size = UDim2.new(0, 40, 0, 10) -- Меньше для чисел
    HealthText.Position = UDim2.new(-12, 0, 0.2, 0) -- Слева от бара, чуть выше центра
    HealthText.TextScaled = true
    HealthText.BackgroundTransparency = 1
    HealthText.TextColor3 = Color3.fromRGB(255, 255, 255) -- Белый текст
    HealthText.Font = Enum.Font.SourceSansBold -- Жирный для лучшей читаемости
    HealthText.TextStrokeTransparency = 0 -- Без обводки для белого текста
    HealthText.ZIndex = 2
    HealthText.Parent = HealthBarGui
    
    Highlights[plr].HealthBar = HealthBarGui
    Highlights[plr].HealthFill = HealthBarFill
    Highlights[plr].HealthText = HealthText
end

local function UpdateHealthBar(plr)
    local highlightEntry = Highlights[plr]
    if not highlightEntry or not highlightEntry.HealthBar or not plr.Character then return end
    
    local humanoid = plr.Character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local fillFrame = highlightEntry.HealthFill
    local ratio = humanoid.Health / humanoid.MaxHealth
    
    -- Обновление размера для вертикальной полосы: 100% ширина, 'ratio' высота
    fillFrame.Size = UDim2.new(1, 0, ratio, 0) 
    
    -- Цвет заполнения всегда белый (уже задан в CreateHealthBar)
    -- Если бы нужно было менять оттенок, логика была бы здесь
    
    -- Обновление текста HP (только текущее HP, округление)
    highlightEntry.HealthText.Text = string.format("%d", math.floor(humanoid.Health))
end

-- ============================== ОСНОВНАЯ ЛОГИКА ==============================

local function CreateESP(plr)
    if plr == LocalPlayer or Highlights[plr] then return end
    if not IsEnemy(plr) then return end
    if not plr.Character then return end

    local hl = Instance.new("Highlight")
    hl.Adornee = plr.Character
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 1
    hl.OutlineTransparency = 0
    hl.OutlineColor = Color3.fromRGB(255, 0, 0) -- Начальный красный цвет
    hl.Enabled = true
    hl.Parent = plr.Character
    
    Highlights[plr] = { Highlight = hl }

    if VisCheckEnabled then UpdateESPColor(plr) end
    if HealthBarEnabled then CreateHealthBar(plr) end
end

local function UpdateAll()
    local playersToCleanup = {}
    
    for plr, hlEntry in pairs(Highlights) do 
        if not plr.Character or not IsEnemy(plr) or not ESPEnabled then 
            if hlEntry.Highlight and hlEntry.Highlight.Parent then pcall(function() hlEntry.Highlight:Destroy() end) end
            if hlEntry.HealthBar and hlEntry.HealthBar.Parent then pcall(function() hlEntry.HealthBar:Destroy() end) end
            table.insert(playersToCleanup, plr)
        end
    end
    for _, plr in ipairs(playersToCleanup) do Highlights[plr] = nil end
    
    if ESPEnabled then
        for _, plr in pairs(P:GetPlayers()) do
            if plr ~= LocalPlayer and IsEnemy(plr) and not Highlights[plr] then 
                CreateESP(plr)
            end
        end
    end
end

-- События
Players.PlayerAdded:Connect(function(p) 
    p.CharacterAdded:Connect(function() 
        task.wait(2) 
        if ESPEnabled then CreateESP(p) end 
    end) 
end)

-- Обновление Health Bar и Vis Check
RunService.RenderStepped:Connect(function()
    if ESPEnabled then
        for plr, hlEntry in pairs(L) do -- L - это Highlights
            if plr.Character then 
                if HealthBarEnabled and hlEntry.HealthBar then UpdateHealthBar(plr) end
                if VisCheckEnabled and hlEntry.Highlight then UpdateESPColor(plr) end
            end
        end
    end
end)

-- Периодическая проверка
task.spawn(function()
    while task.wait(5) do 
        if ESPEnabled then UpdateAll() end 
    end
end)

-- Автостарт
task.wait(1)
UpdateAll()

print("The Lost Front ESP Activated!")
