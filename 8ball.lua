
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "8ball hub",
    SubTitle = "One piece:Mythical",
    TabWidth = 120,
    Size = UDim2.fromOffset(450, 300),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

Tabs.Misc = Window:AddTab({ Title = "Misc", Icon = "globe" })

Tabs.ESP = Window:AddTab({ Title = "ESP", Icon = "eye" })


local Players = game:GetService("Players")
local player = Players.LocalPlayer

local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(char)
    character = char
    humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

-- 🍹 AutoDrink
local autoDrink = false
local drinks = {
    ["sour juice"] = true,
    ["pear juice"] = true,
    ["fruit juice"] = true,
    ["banana juice"] = true,
    ["coconut milk"] = true,
    ["pumpkin juice"] = true,
    ["apple juice"] = true
}

Tabs.Main:AddToggle("AutoDrink", {
    Title = "AutoDrink",
    Default = false,
    Callback = function(state)
        autoDrink = state
    end
})

local function tryDrink(item)
    if autoDrink and item:IsA("Tool") and drinks[item.Name:lower()] then
        if not character or not character:FindFirstChild("Humanoid") then return end
        item.Parent = character
        task.wait(0.1)
        item:Activate()
    end
end

player.Backpack.ChildAdded:Connect(function(item)
    tryDrink(item)
end)

task.spawn(function()
    while true do
        if autoDrink then
            if not character or not character:FindFirstChild("Humanoid") then
                character = player.Character or player.CharacterAdded:Wait()
            end
            for _, item in ipairs(player.Backpack:GetChildren()) do
                tryDrink(item)
            end
        end
        task.wait(1)
    end
end)

-- 🚀 Farm Fruits Nearby
local autoFarmFruits = false
local farmDistance = 300

Tabs.Main:AddToggle("AutoFarm Fruits", {
    Title = "Farm Fruits Nearby",
    Default = false,
    Callback = function(state)
        autoFarmFruits = state
    end
})

local Slider = Tabs.Main:AddSlider("FarmDistanceSlider", {
    Title = "Farm Distance",
    Description = "max distance to object",
    Default = 300,
    Min = 50,
    Max = 10000,
    Rounding = 0,
    Callback = function(value)
        farmDistance = value
    end
})

Slider:SetValue(300)

task.spawn(function()
    local targets = {"Crate", "Barrels"}
    while true do
        if not autoFarmFruits then
            task.wait(0.1)
            continue
        end

        if not character or not humanoidRootPart then
            character = player.Character or player.CharacterAdded:Wait()
            humanoidRootPart = character:WaitForChild("HumanoidRootPart")
        end

        for _, obj in ipairs(workspace:GetDescendants()) do
            if not autoFarmFruits then break end
            if table.find(targets, obj.Name) and obj:IsA("BasePart") then
                local distance = (humanoidRootPart.Position - obj.Position).Magnitude
                if distance <= farmDistance then
                    humanoidRootPart.CFrame = obj.CFrame + Vector3.new(0, -4, 0)
                    task.wait(0.2)
                    local clickDetector = obj:FindFirstChildOfClass("ClickDetector")
                    if clickDetector then
                        fireclickdetector(clickDetector)
                        task.wait(0.3)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- 🧪 AutoMixer
local autoMixer = false

Tabs.Main:AddToggle("AutoMixer", {
    Title = "AutoMixer",
    Default = false,
    Callback = function(state)
        autoMixer = state
    end
})

local bowlCFrame = CFrame.new(1993.2998, 218.693359, 563.104553)
local mixerRadius = 3
local mixerInterval = 40

local function safeFireClickDetector(cd)
    pcall(function() fireclickdetector(cd) end)
end

local function safeFirePrompt(prompt)
    pcall(function()
        fireproximityprompt(prompt, prompt.HoldDuration and prompt.HoldDuration > 0 and prompt.HoldDuration or 0)
    end)
end

local function clickAround(position, radius)
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Whitelist
    overlap.FilterDescendantsInstances = {workspace}

    local parts = workspace:GetPartBoundsInRadius(position, radius, overlap)
    if not parts then return end

    local seen = {}

    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            for _, obj in ipairs({part, unpack(part:GetDescendants())}) do
                if obj:IsA("ClickDetector") and not seen[obj] then
                    safeFireClickDetector(obj)
                    seen[obj] = true
                    task.wait(0.05)
                elseif obj:IsA("ProximityPrompt") and not seen[obj] then
                    safeFirePrompt(obj)
                    seen[obj] = true
                    task.wait(0.05)
                end
            end

            local parent = part.Parent
            while parent do
                for _, ch in ipairs(parent:GetChildren()) do
                    if ch:IsA("ClickDetector") and not seen[ch] then
                        safeFireClickDetector(ch)
                        seen[ch] = true
                        task.wait(0.05)
                    elseif ch:IsA("ProximityPrompt") and not seen[ch] then
                        safeFirePrompt(ch)
                        seen[ch] = true
                        task.wait(0.05)
                    end
                end
                parent = parent.Parent
            end
        end
    end
end

task.spawn(function()
    while true do
        if autoMixer and humanoidRootPart then
            humanoidRootPart.CFrame = bowlCFrame + Vector3.new(0, 3, 0)
            task.wait(0.2)
            clickAround(bowlCFrame.Position, mixerRadius)
        end
        task.wait(mixerInterval)
    end
end)

-- === Noclip toggle (collisions only) ===
local RunService = game:GetService("RunService")

local noclipEnabled = false
local originalCollide = {}   -- [BasePart] = boolean
local hbConn, charConn

local function applyNoclipToCharacter(char)
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            if originalCollide[obj] == nil then
                originalCollide[obj] = obj.CanCollide
            end
            obj.CanCollide = false
        end
    end
end

local function restoreCollisions()
    for part, can in pairs(originalCollide) do
        if part and part.Parent then
            part.CanCollide = can
        end
    end
    table.clear(originalCollide)
end

local function enableNoclip()
    if noclipEnabled then return end
    noclipEnabled = true
    -- сразу применим на текущего персонажа
    applyNoclipToCharacter(player.Character)
    -- при каждом кадре поддерживаем noclip (на случай новых частей)
    hbConn = RunService.Heartbeat:Connect(function()
        if not noclipEnabled then return end
        local char = player.Character
        if char then
            applyNoclipToCharacter(char)
        end
    end)
    -- если персонаж респавнится — реинициализируем
    charConn = player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 10)
        task.wait() -- маленькая пауза, чтобы части успели появиться
        if noclipEnabled then
            applyNoclipToCharacter(char)
        end
    end)
end

local function disableNoclip()
    if not noclipEnabled then return end
    noclipEnabled = false
    if hbConn then hbConn:Disconnect() hbConn = nil end
    if charConn then charConn:Disconnect() charConn = nil end
    restoreCollisions()
    -- поднимем гуманоид в нормальное состояние на всякий случай
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        pcall(function()
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
end

-- UI toggle в Misc
Tabs.Misc:AddToggle("NoclipToggle", {
    Title = "Enable Noclip",
    Default = false,
    Callback = function(state)
        if state then
            enableNoclip()
        else
            disableNoclip()
        end
    end
})

local espEnabled = false
local espObjects = {}

-- 🔁 Обновление ESP
local function updateESP()
    for _, v in pairs(espObjects) do
        if v and v.Parent then
            v:Destroy()
        end
    end
    table.clear(espObjects)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_" .. plr.Name
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 100, 0, 20)
            billboard.StudsOffset = Vector3.new(0, 2, 0)
            billboard.AlwaysOnTop = true
            billboard.Parent = head

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = plr.Name
            label.TextColor3 = Color3.new(1, 0, 0)
            label.TextStrokeTransparency = 0.5
            label.TextScaled = true
            label.Font = Enum.Font.SourceSansBold
            label.Parent = billboard

            table.insert(espObjects, billboard)
        end
    end
end

-- 🔁 Цикл ESP
task.spawn(function()
    while true do
        if espEnabled then
            updateESP()
        else
            for _, v in pairs(espObjects) do
                if v and v.Parent then
                    v:Destroy()
                end
            end
            table.clear(espObjects)
        end
        task.wait(1)
    end
end)


    Tabs.Misc:AddParagraph({
        Title = "credit:.aatron",
        Content = "discord:/Nigger"
    })


-- 🎛️ Переключатель ESP Player
Tabs.ESP:AddToggle("ESPPlayerToggle", {
    Title = "ESP Player",
    Description = "Показывает игроков через стены",
    Default = false,
    Callback = function(state)
        espEnabled = state
    end
})
-- 📡 ESP NPC
local espNPCEnabled = false
local espNPCObjects = {}

local function updateESPNPC()
    for _, v in pairs(espNPCObjects) do
        if v and v.Parent then
            v:Destroy()
        end
    end
    table.clear(espNPCObjects)

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, model in ipairs(workspace:GetDescendants()) do
        if model:IsA("Model") and model:FindFirstChild("Humanoid") and model:FindFirstChild("Head") then
            if not Players:GetPlayerFromCharacter(model) then
                local head = model.Head
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "ESP_NPC_" .. model.Name
                billboard.Adornee = head
                billboard.Size = UDim2.new(0, 100, 0, 30)
                billboard.StudsOffset = Vector3.new(0, 2, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = head

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.TextColor3 = Color3.new(0, 1, 0)
                label.TextStrokeTransparency = 0.5
                label.TextScaled = true
                label.Font = Enum.Font.SourceSansBold
                label.Parent = billboard

                table.insert(espNPCObjects, billboard)

                -- Обновление текста с дистанцией
                task.spawn(function()
                    while espNPCEnabled and billboard.Parent do
                        local dist = (hrp.Position - head.Position).Magnitude
                        label.Text = model.Name .. " [" .. math.floor(dist) .. "m]"
                        task.wait(0.5)
                    end
                end)
            end
        end
    end
end


-- 🔁 Цикл ESP NPC
task.spawn(function()
    while true do
        if espNPCEnabled then
            updateESPNPC()
        else
            for _, v in pairs(espNPCObjects) do
                if v and v.Parent then
                    v:Destroy()
                end
            end
            table.clear(espNPCObjects)
        end
        task.wait(1)
    end
end)

-- 💤 AntiAFK
local antiAFKEnabled = false
local vu = game:GetService("VirtualUser")

Tabs.Main:AddToggle("AntiAFKToggle", {
    Title = "AntiAFK",
    Description = "make you didnt kicked",
    Default = false,
    Callback = function(state)
        antiAFKEnabled = state
    end
})

-- 🔁 Цикл AntiAFK
task.spawn(function()
    while true do
        if antiAFKEnabled then
            vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end
        task.wait(60)
    end
end)

-- 🎛️ Переключатель ESP NPC
Tabs.ESP:AddToggle("ESPNPCToggle", {
    Title = "ESP NPC",
    Description = "Показывает NPC через стены",
    Default = false,
    Callback = function(state)
        espNPCEnabled = state
    end
})


-- 💾 Сохранение
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

InterfaceManager:SetFolder("8ballHub")
SaveManager:SetFolder("8ballHub/Mythical")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
