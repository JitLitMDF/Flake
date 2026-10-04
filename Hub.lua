--[[
    Flake // Hub.lua
    The main script hub (loads after the key gate authorizes).
    Modern restyle of FlakeMainScriptHubSIA51: draggable window with glide,
    tab rail, a real component kit (button / toggle / slider / number input),
    minimize-to-icon, and game-agnostic features wired up for real.
    Made by JitLit_MDF
]]

local BASE = "https://raw.githubusercontent.com/JitLitMDF/Flake/main/"

local Flake = getgenv and getgenv().Flake
if not (Flake and Flake.Helpers) then
    Flake = loadstring(game:HttpGet(BASE .. "Shared.lua"))()
end
local H = Flake.Helpers

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")

local LP = Players.LocalPlayer

----------------------------------------------------------------------
-- Theme (matches the keysystem)
----------------------------------------------------------------------
local PANEL_BG  = Color3.fromRGB(37, 37, 37)
local BAR_BG    = Color3.fromRGB(44, 44, 44)
local ROW_BG    = Color3.fromRGB(54, 54, 54)
local FIELD_BG  = Color3.fromRGB(64, 64, 64)
local BTN_BG    = Color3.fromRGB(80, 80, 80)
local BTN_HOV   = Color3.fromRGB(96, 96, 96)
local BTN_PRESS = Color3.fromRGB(66, 66, 66)
local TEXT_MAIN = Color3.fromRGB(241, 241, 241)
local TEXT_DIM  = Color3.fromRGB(150, 150, 150)
local STROKE    = Color3.fromRGB(255, 255, 255)
local ACCENT    = Color3.fromRGB(235, 235, 235)
local ON_COLOR  = Color3.fromRGB(104, 190, 120)
local OFF_COLOR = Color3.fromRGB(70, 70, 70)
local MICHROMA  = "rbxasset://fonts/families/Michroma.json"
local SPIN_ICON = "rbxassetid://110507486450516"

local FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local function michroma(w) return Font.new(MICHROMA, w or Enum.FontWeight.Medium) end
local function corner(p, r) return H.make("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p) end
local function stroke(p, t, c) return H.make("UIStroke", { Color = c or STROKE, Thickness = t or 1, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Round }, p) end
local function cap(o, mx, mn) H.make("UITextSizeConstraint", { MaxTextSize = mx or 18, MinTextSize = mn or 6 }, o) end
local function tween(o, ti, props) return TweenService:Create(o, ti, props) end

----------------------------------------------------------------------
-- Glide drag (shared with the keysystem feel)
----------------------------------------------------------------------
local function glider(target, handle)
    local goal = target.Position
    local dragging, dragStart, startPos
    handle.Active = true
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = goal
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            goal = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if not target.Parent then conn:Disconnect(); return end
        target.Position = target.Position:Lerp(goal, 1 - math.exp(-dt * 15))
    end)
    return { set = function(p) goal = p end, get = function() return goal end }
end

----------------------------------------------------------------------
-- Build window
----------------------------------------------------------------------
local old = H.guiParent():FindFirstChild("FlakeHub")
if old then old:Destroy() end

local screen = H.make("ScreenGui", {
    Name = "FlakeHub", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 10000, IgnoreGuiInset = true,
})
H.protect(screen)
screen.Parent = H.guiParent()

local win = H.make("Frame", {
    Name = "Window", Size = UDim2.fromOffset(600, 390), Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = PANEL_BG,
}, screen)
H.make("UIAspectRatioConstraint", { AspectRatio = 600 / 390, AspectType = Enum.AspectType.ScaleWithParentSize, DominantAxis = Enum.DominantAxis.Width }, win)
H.make("UISizeConstraint", { MinSize = Vector2.new(480, 312), MaxSize = Vector2.new(760, 494) }, win)
H.make("UIScale", { Scale = 1 }, win)
H.make("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 28)) }), Offset = Vector2.new(0, 10) }, win)
corner(win, 12)
stroke(win, 2).Transparency = 0.15
H.make("ImageLabel", {
    Name = "Shadow", Size = UDim2.new(1, 60, 1, 60), Position = UDim2.new(0.5, 0, 0.5, 8), AnchorPoint = Vector2.new(0.5, 0.5),
    ZIndex = -1, BackgroundTransparency = 1, Image = "rbxassetid://6015897843", ImageColor3 = Color3.fromRGB(0, 0, 0),
    ImageTransparency = 0.4, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 463, 463),
}, win)

-- Top bar
local bar = H.make("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = BAR_BG }, win)
corner(bar, 12)
H.make("Frame", { Name = "BarMask", Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 0, 1, -14), BackgroundColor3 = BAR_BG, BorderSizePixel = 0 }, bar) -- square off bottom of the rounded bar

local titleLbl = H.make("TextLabel", {
    Name = "HubTopName", Size = UDim2.new(0.5, 0, 0, 24), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, Text = "FlakeHub", TextColor3 = TEXT_MAIN, TextScaled = true, FontFace = michroma(Enum.FontWeight.Bold),
}, bar)
cap(titleLbl, 22)

local function barButton(name, txt, xoff)
    local b = H.make("TextButton", {
        Name = name, Size = UDim2.fromOffset(74, 26), Position = UDim2.new(1, xoff, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = BTN_BG, Text = txt, TextColor3 = TEXT_MAIN, TextScaled = true, FontFace = michroma(Enum.FontWeight.Medium), AutoButtonColor = false,
    }, bar)
    corner(b, 6); cap(b, 14)
    b.MouseEnter:Connect(function() tween(b, FAST, { BackgroundColor3 = BTN_HOV }):Play() end)
    b.MouseLeave:Connect(function() tween(b, FAST, { BackgroundColor3 = BTN_BG }):Play() end)
    return b
end
local closeBtn = barButton("Close", "Close", -10)
local minBtn   = barButton("Minimize", "Minimize", -92)

-- Tab rail
local rail = H.make("Frame", { Name = "Rail", Size = UDim2.new(0, 120, 1, -44), Position = UDim2.new(0, 0, 0, 44), BackgroundTransparency = 1 }, win)
H.make("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, rail)
H.make("UIPadding", { PaddingTop = UDim.new(0, 12) }, rail)
H.make("Frame", { Name = "Divider", Size = UDim2.new(0, 1, 1, -60), Position = UDim2.new(0, 120, 0, 52), BackgroundColor3 = Color3.fromRGB(80, 80, 80), BorderSizePixel = 0, BackgroundTransparency = 0.4 }, win)

-- Content host
local content = H.make("Frame", { Name = "Content", Size = UDim2.new(1, -132, 1, -56), Position = UDim2.new(0, 128, 0, 50), BackgroundTransparency = 1 }, win)

----------------------------------------------------------------------
-- Tabs + pages
----------------------------------------------------------------------
local pages, tabButtons = {}, {}
local activeTab
local function selectTab(name)
    for n, pg in pairs(pages) do pg.Visible = (n == name) end
    for n, tb in pairs(tabButtons) do
        local on = (n == name)
        tween(tb, FAST, { BackgroundColor3 = on and BTN_HOV or ROW_BG, TextColor3 = on and TEXT_MAIN or TEXT_DIM }):Play()
        tb:FindFirstChildOfClass("UIStroke").Transparency = on and 0.1 or 0.75
    end
    activeTab = name
end

local function addTab(name)
    local tb = H.make("TextButton", {
        Name = "Tab_" .. name, Size = UDim2.fromOffset(100, 30), BackgroundColor3 = ROW_BG, Text = name, TextColor3 = TEXT_DIM,
        TextScaled = true, FontFace = michroma(Enum.FontWeight.Medium), AutoButtonColor = false, LayoutOrder = #tabButtons + 1,
    }, rail)
    corner(tb, 6); cap(tb, 14); stroke(tb, 1).Transparency = 0.75

    local page = H.make("ScrollingFrame", {
        Name = "Page_" .. name, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false,
        ScrollBarThickness = 4, ScrollBarImageColor3 = Color3.fromRGB(120, 120, 120), CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0,
    }, content)
    H.make("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    H.make("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, page)

    pages[name] = page
    tabButtons[name] = tb
    tb.MouseButton1Click:Connect(function() selectTab(name) end)
    tb.MouseEnter:Connect(function() if activeTab ~= name then tween(tb, FAST, { BackgroundColor3 = Color3.fromRGB(64, 64, 64) }):Play() end end)
    tb.MouseLeave:Connect(function() if activeTab ~= name then tween(tb, FAST, { BackgroundColor3 = ROW_BG }):Play() end end)
    return page
end

----------------------------------------------------------------------
-- Component kit
----------------------------------------------------------------------
local function rowBase(page, h)
    local row = H.make("Frame", { Name = "Row", Size = UDim2.new(1, 0, 0, h or 34), BackgroundColor3 = ROW_BG, LayoutOrder = #page:GetChildren() }, page)
    corner(row, 8); stroke(row, 1).Transparency = 0.8
    return row
end

local function addButton(page, text, callback)
    local row = rowBase(page, 34)
    local b = H.make("TextButton", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = text, TextColor3 = TEXT_MAIN, TextScaled = true,
        FontFace = michroma(Enum.FontWeight.Medium), AutoButtonColor = false,
    }, row)
    cap(b, 15)
    b.MouseEnter:Connect(function() tween(row, FAST, { BackgroundColor3 = BTN_HOV }):Play() end)
    b.MouseLeave:Connect(function() tween(row, FAST, { BackgroundColor3 = ROW_BG }):Play() end)
    b.MouseButton1Down:Connect(function() tween(row, FAST, { BackgroundColor3 = BTN_PRESS }):Play() end)
    b.MouseButton1Up:Connect(function() tween(row, FAST, { BackgroundColor3 = BTN_HOV }):Play() end)
    b.MouseButton1Click:Connect(function() pcall(callback) end)
    return row
end

local function addToggle(page, text, default, callback)
    local row = rowBase(page, 36)
    H.make("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = TEXT_MAIN,
        TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, FontFace = michroma(Enum.FontWeight.Regular),
    }, row)
    cap(row:FindFirstChildOfClass("TextLabel"), 14)
    local track = H.make("TextButton", {
        Size = UDim2.fromOffset(44, 22), Position = UDim2.new(1, -14, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = OFF_COLOR, Text = "", AutoButtonColor = false,
    }, row)
    corner(track, 11)
    local knob = H.make("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 3, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = TEXT_MAIN }, track)
    corner(knob, 8)

    local state = default and true or false
    local function apply(v, fire)
        state = v
        tween(track, FAST, { BackgroundColor3 = state and ON_COLOR or OFF_COLOR }):Play()
        tween(knob, TweenInfo.new(0.16, Enum.EasingStyle.Quad), { Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }):Play()
        if fire then pcall(callback, state) end
    end
    track.MouseButton1Click:Connect(function() apply(not state, true) end)
    apply(state, false)
    return { set = function(v) apply(v, true) end, get = function() return state end }
end

local function addSlider(page, text, min, max, default, callback)
    local row = rowBase(page, 48)
    H.make("TextLabel", {
        Size = UDim2.new(1, -70, 0, 18), Position = UDim2.new(0, 14, 0, 6), BackgroundTransparency = 1, Text = text, TextColor3 = TEXT_MAIN,
        TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, FontFace = michroma(Enum.FontWeight.Regular),
    }, row)
    cap(row:FindFirstChildOfClass("TextLabel"), 14)
    local valLbl = H.make("TextLabel", {
        Name = "Val", Size = UDim2.fromOffset(60, 18), Position = UDim2.new(1, -14, 0, 6), AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1, Text = tostring(default), TextColor3 = TEXT_DIM, TextXAlignment = Enum.TextXAlignment.Right,
        TextScaled = true, FontFace = michroma(Enum.FontWeight.Medium),
    }, row)
    cap(valLbl, 14)
    local bar = H.make("Frame", { Size = UDim2.new(1, -28, 0, 6), Position = UDim2.new(0, 14, 1, -14), BackgroundColor3 = FIELD_BG }, row)
    corner(bar, 3)
    local fill = H.make("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = ON_COLOR }, bar)
    corner(fill, 3)
    local knob = H.make("TextButton", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = TEXT_MAIN, Text = "", AutoButtonColor = false }, bar)
    corner(knob, 7)

    local value = default
    local function setVal(v, fire)
        v = math.clamp(math.floor(v + 0.5), min, max)
        value = v
        local alpha = (v - min) / (max - min)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valLbl.Text = tostring(v)
        if fire then pcall(callback, v) end
    end
    local dragging = false
    local function fromX(px)
        local alpha = math.clamp((px - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        setVal(min + alpha * (max - min), true)
    end
    knob.MouseButton1Down:Connect(function() dragging = true end)
    bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; fromX(i.Position.X) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
    UserInputService.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then fromX(i.Position.X) end end)
    task.defer(setVal, default, false)
    return { set = function(v) setVal(v, true) end, get = function() return value end }
end

local function addInput(page, text, placeholder, callback)
    local row = rowBase(page, 36)
    H.make("TextLabel", {
        Size = UDim2.new(0.5, -14, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = TEXT_MAIN,
        TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, FontFace = michroma(Enum.FontWeight.Regular),
    }, row)
    cap(row:FindFirstChildOfClass("TextLabel"), 14)
    local box = H.make("TextBox", {
        Size = UDim2.new(0.45, 0, 0, 24), Position = UDim2.new(1, -14, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = FIELD_BG,
        Text = "", PlaceholderText = placeholder or "", PlaceholderColor3 = Color3.fromRGB(120, 120, 120), TextColor3 = TEXT_MAIN,
        TextScaled = true, ClearTextOnFocus = false, FontFace = michroma(Enum.FontWeight.Regular),
    }, row)
    corner(box, 6); cap(box, 14)
    H.make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then pcall(callback, box.Text) end
    end)
    return box
end

local function addLabel(page, text)
    local l = H.make("TextLabel", {
        Name = "Label", Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = text, TextColor3 = TEXT_DIM,
        TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, FontFace = michroma(Enum.FontWeight.Regular), LayoutOrder = #page:GetChildren(),
    }, page)
    cap(l, 12)
    return l
end

----------------------------------------------------------------------
-- Character / feature helpers (game-agnostic)
----------------------------------------------------------------------
local function getChar() return LP.Character or LP.CharacterAdded:Wait() end
local function getHum() local c = getChar(); return c:FindFirstChildOfClass("Humanoid") end
local function getRoot() local c = getChar(); return c:FindFirstChild("HumanoidRootPart") end

-- persisted values that must survive respawns
local desiredWS, desiredJP = nil, nil
local function applyPersisted()
    local hum = getHum()
    if hum then
        if desiredWS then hum.WalkSpeed = desiredWS end
        if desiredJP then hum.UseJumpPower = true; hum.JumpPower = desiredJP end
    end
end
if LP then LP.CharacterAdded:Connect(function() task.wait(0.4); applyPersisted() end) end

-- Infinite jump
local infJump = false
UserInputService.JumpRequest:Connect(function()
    if infJump then local h = getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- Noclip
local noclip = false
RunService.Stepped:Connect(function()
    if noclip then
        local c = LP.Character
        if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end end end
    end
end)

-- Fly
local flying = false
local flySpeed = 2
do
    local bg, bv
    local flyConn
    local function stopFly()
        flying = false
        if bg then bg:Destroy(); bg = nil end
        if bv then bv:Destroy(); bv = nil end
        if flyConn then flyConn:Disconnect(); flyConn = nil end
    end
    local function startFly()
        local root = getRoot(); if not root then return end
        flying = true
        bg = Instance.new("BodyGyro"); bg.P = 9e4; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.CFrame = root.CFrame; bg.Parent = root
        bv = Instance.new("BodyVelocity"); bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.zero; bv.Parent = root
        flyConn = RunService.RenderStepped:Connect(function()
            if not flying or not root.Parent then stopFly(); return end
            local cam = Workspace.CurrentCamera
            local dir = Vector3.zero
            local function down(k) return UserInputService:IsKeyDown(k) end
            if down(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if down(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if down(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if down(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if down(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if down(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
            bg.CFrame = cam.CFrame
            bv.Velocity = (dir == Vector3.zero and Vector3.zero or dir.Unit * (flySpeed * 25))
        end)
    end
    _G.__flakeSetFly = function(on) if on then startFly() else stopFly() end end
    _G.__flakeSetFlySpeed = function(s) flySpeed = s end
end

-- ESP (highlights)
local espOn = false
local espFolder
local function clearESP()
    if espFolder then espFolder:Destroy(); espFolder = nil end
end
local function highlightPlayer(plr)
    if plr == LP then return end
    local function hook(char)
        if not espOn then return end
        local hl = Instance.new("Highlight")
        hl.Name = "FlakeESP"; hl.FillColor = Color3.fromRGB(120, 170, 255); hl.FillTransparency = 0.6
        hl.OutlineColor = Color3.fromRGB(255, 255, 255); hl.OutlineTransparency = 0
        hl.Adornee = char; hl.Parent = espFolder
        char.AncestryChanged:Connect(function(_, parent) if not parent and hl then hl:Destroy() end end)
    end
    if plr.Character then hook(plr.Character) end
    plr.CharacterAdded:Connect(hook)
end
local function setESP(on)
    espOn = on
    clearESP()
    if on then
        espFolder = Instance.new("Folder"); espFolder.Name = "FlakeESPFolder"; espFolder.Parent = H.guiParent()
        for _, p in ipairs(Players:GetPlayers()) do highlightPlayer(p) end
        Players.PlayerAdded:Connect(function(p) if espOn then highlightPlayer(p) end end)
    end
end

-- Fullbright
local fullbright = false
local savedLighting
local function setFullbright(on)
    fullbright = on
    if on then
        savedLighting = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient }
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 1e9; Lighting.GlobalShadows = false; Lighting.Ambient = Color3.fromRGB(180, 180, 180)
    elseif savedLighting then
        for k, v in pairs(savedLighting) do Lighting[k] = v end
    end
end

local function teleportToSpawn()
    local root = getRoot(); if not root then return end
    local sp = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    if sp then root.CFrame = sp.CFrame + Vector3.new(0, 4, 0) end
end

----------------------------------------------------------------------
-- Pages + controls
----------------------------------------------------------------------
local pgTP   = addTab("TPs")
local pgESP  = addTab("ESP")
local pgPL   = addTab("PLAYER")
local pgAF   = addTab("AUTOFARM")
local pgOT   = addTab("OTHERS")

-- TPs
addLabel(pgTP, "Teleports")
addButton(pgTP, "Spawn", teleportToSpawn)
addButton(pgTP, "To random player", function()
    local others = {}
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then table.insert(others, p) end end
    if #others > 0 then local t = others[math.random(1, #others)]; local r = getRoot(); if r then r.CFrame = t.Character.HumanoidRootPart.CFrame end end
end)

-- ESP
addLabel(pgESP, "Visuals")
addToggle(pgESP, "Player Highlights", false, setESP)
addToggle(pgESP, "Fullbright", false, setFullbright)

-- PLAYER
addLabel(pgPL, "Movement")
addSlider(pgPL, "Walkspeed", 16, 500, 16, function(v) desiredWS = v; local h = getHum(); if h then h.WalkSpeed = v end end)
addSlider(pgPL, "Jump Power", 50, 500, 50, function(v) desiredJP = v; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = v end end)
addInput(pgPL, "Set JumpPower:", "number", function(txt) local n = tonumber(txt); if n then desiredJP = n; local h = getHum(); if h then h.UseJumpPower = true; h.JumpPower = n end end end)
addToggle(pgPL, "Infinite Jump", false, function(v) infJump = v end)
addToggle(pgPL, "Fly  (W/A/S/D + Space/Shift)", false, function(v) _G.__flakeSetFly(v) end)
addSlider(pgPL, "Fly Speed", 1, 20, 2, function(v) _G.__flakeSetFlySpeed(v) end)
addToggle(pgPL, "Noclip", false, function(v) noclip = v end)
addButton(pgPL, "Reset Character", function() local h = getHum(); if h then h.Health = 0 end end)

-- AUTOFARM (game-specific hooks go here)
addLabel(pgAF, "Auto Farm")
addLabel(pgAF, "Game-specific — wire these per supported game.")
addToggle(pgAF, "Auto Farm (placeholder)", false, function(_) end)

-- OTHERS
addLabel(pgOT, "Misc")
addButton(pgOT, "Rejoin Server", function()
    local ok = pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LP) end)
    if not ok then warn("[Flake] rejoin failed") end
end)
addButton(pgOT, "Copy Place ID", function() local f = setclipboard or (syn and syn.write_clipboard) or toclipboard; if f then pcall(f, tostring(game.PlaceId)) end end)
addLabel(pgOT, "Credits")
addButton(pgOT, "Made by JitLit_MDF", function() end)

selectTab("TPs")

----------------------------------------------------------------------
-- Drag + minimize + close
----------------------------------------------------------------------
local winGlide = glider(win, bar)

local minimized = H.make("ImageButton", {
    Name = "MinIcon", Size = UDim2.fromOffset(52, 52), Position = UDim2.new(0, 20, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = BAR_BG, Image = SPIN_ICON, ImageColor3 = TEXT_MAIN, ScaleType = Enum.ScaleType.Fit, Visible = false,
}, screen)
corner(minimized, 12); stroke(minimized, 2).Transparency = 0.2
H.make("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, minimized)
local minGlide = glider(minimized, minimized)

minBtn.MouseButton1Click:Connect(function()
    local sc = win:FindFirstChildOfClass("UIScale")
    tween(sc, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 }):Play()
    task.wait(0.22)
    win.Visible = false; sc.Scale = 1
    minimized.Visible = true
end)
minimized.MouseButton1Click:Connect(function()
    minimized.Visible = false
    win.Visible = true
    local sc = win:FindFirstChildOfClass("UIScale")
    sc.Scale = 0.85
    tween(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end)

closeBtn.MouseButton1Click:Connect(function()
    setESP(false); setFullbright(false); _G.__flakeSetFly(false); noclip = false; infJump = false
    local sc = win:FindFirstChildOfClass("UIScale")
    tween(sc, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 }):Play()
    tween(win, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
    task.wait(0.3)
    screen:Destroy()
end)

-- Entrance
local sc = win:FindFirstChildOfClass("UIScale")
sc.Scale = 0.9
win.Position = UDim2.new(0.5, 0, 0.5, 20)
winGlide.set(UDim2.new(0.5, 0, 0.5, 0))
tween(sc, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

getgenv().FlakeHubLoaded = true
return Flake
