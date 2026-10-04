--[[
    Flake // Keysystem.lua
    Key gate: loader handoff, validates the key, fires OnAuthorized.
    Draggable (with glide), closable, fully scale-based so it fits any screen.
    Made by JitLit_MDF
]]

local BASE = "https://raw.githubusercontent.com/JitLitMDF/Flake/main/"

local Flake = getgenv and getgenv().Flake
if not (Flake and Flake.Helpers) then
    Flake = loadstring(game:HttpGet(BASE .. "Shared.lua"))()
end
local H = Flake.Helpers

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

----------------------------------------------------------------------
-- Config
----------------------------------------------------------------------
local KEY       = "PRIVATEOCTOBER26"
local KEY_LINK  = ""                          -- optional getkey URL for the clipboard
local WAIT_FOR_LOADER = true

local PANEL_BG  = Color3.fromRGB(47, 47, 47)
local FIELD_BG  = Color3.fromRGB(60, 60, 60)
local FIELD_FOC = Color3.fromRGB(72, 72, 72)
local BTN_BG    = Color3.fromRGB(80, 80, 80)
local BTN_HOV   = Color3.fromRGB(96, 96, 96)
local BTN_PRESS = Color3.fromRGB(66, 66, 66)
local TEXT_MAIN = Color3.fromRGB(241, 241, 241)
local TEXT_DIM  = Color3.fromRGB(150, 150, 150)
local STROKE    = Color3.fromRGB(255, 255, 255)
local OK_COLOR  = Color3.fromRGB(104, 190, 120)
local BAD_COLOR = Color3.fromRGB(205, 96, 96)
local MICHROMA  = "rbxasset://fonts/families/Michroma.json"

local FAST = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function michroma(w) return Font.new(MICHROMA, w or Enum.FontWeight.Bold) end
local function corner(p, r) return H.make("UICorner", { CornerRadius = UDim.new(0, r or 6) }, p) end
-- scale-driven label: TextScaled + a sane max so it never balloons or squashes
local function cap(o, mx, mn) H.make("UITextSizeConstraint", { MaxTextSize = mx or 22, MinTextSize = mn or 6 }, o) end

local function wireButton(btn, base, hov, press)
    local hovering = false
    btn.AutoButtonColor = false
    btn.MouseEnter:Connect(function() hovering = true;  TweenService:Create(btn, FAST, { BackgroundColor3 = hov }):Play() end)
    btn.MouseLeave:Connect(function() hovering = false; TweenService:Create(btn, FAST, { BackgroundColor3 = base }):Play() end)
    btn.MouseButton1Down:Connect(function() TweenService:Create(btn, FAST, { BackgroundColor3 = press }):Play() end)
    btn.MouseButton1Up:Connect(function() TweenService:Create(btn, FAST, { BackgroundColor3 = hovering and hov or base }):Play() end)
end

-- Shared card chrome (bg, gradient, rounded corners, stroke, soft 9-slice shadow)
local function card(parent, w, h)
    local f = H.make("Frame", {
        Name = "Frame",
        Size = UDim2.fromOffset(w, h),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = PANEL_BG,
    }, parent)
    H.make("UIAspectRatioConstraint", { AspectRatio = w / h, AspectType = Enum.AspectType.ScaleWithParentSize, DominantAxis = Enum.DominantAxis.Width }, f)
    H.make("UISizeConstraint", { MinSize = Vector2.new(w * 0.8, h * 0.8), MaxSize = Vector2.new(w * 1.25, h * 1.25) }, f)
    H.make("UIScale", { Scale = 1 }, f)
    H.make("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 21, 21)),
        }),
        Offset = Vector2.new(0, 10),
    }, f)
    corner(f, 12)
    H.make("UIStroke", { Color = STROKE, Thickness = 2, Transparency = 0.15, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Round }, f)
    H.make("ImageLabel", {
        Name = "Shadow", Size = UDim2.new(1, 60, 1, 60), Position = UDim2.new(0.5, 0, 0.5, 8),
        AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = -1, BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843", ImageColor3 = Color3.fromRGB(0, 0, 0), ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 463, 463),
    }, f)
    return f
end

-- A square close/back "X" button in a card's top-right
local function closeButton(parent)
    local b = H.make("TextButton", {
        Name = "Close", Size = UDim2.new(0.055, 0, 0.11, 0), Position = UDim2.new(0.92, 0, 0.11, 0),
        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1, Text = "X",
        TextColor3 = TEXT_DIM, TextScaled = true, FontFace = michroma(Enum.FontWeight.Bold), AutoButtonColor = false,
    }, parent)
    H.make("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, b)
    cap(b, 20)
    b.MouseEnter:Connect(function() TweenService:Create(b, FAST, { TextColor3 = BAD_COLOR }):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b, FAST, { TextColor3 = TEXT_DIM }):Play() end)
    return b
end

-- Glide-drag: the card smoothly chases a target position (lag while moving,
-- settle/glide when you let go). The same target drives pop in/out.
local function glider(card)
    local target = card.Position
    local dragging, dragStart, startPos
    card.Active = true
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = target
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            target = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    local conn
    conn = RunService.RenderStepped:Connect(function(dt)
        if not card.Parent then conn:Disconnect(); return end
        local a = 1 - math.exp(-dt * 15)         -- smoothing = the glide
        card.Position = card.Position:Lerp(target, a)
    end)
    return {
        set = function(p) target = p end,
        get = function() return target end,
    }
end

local function popIn(card, centerPos)
    local scale = card:FindFirstChildOfClass("UIScale")
    card.Position = centerPos + UDim2.fromScale(0, 0.35)
    scale.Scale = 0.92
    TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

----------------------------------------------------------------------
-- Wait for the loader
----------------------------------------------------------------------
if WAIT_FOR_LOADER and not Flake.Loaded then
    task.delay(6, function() if not Flake.Loaded then Flake.OnLoaded:Fire() end end)
    Flake.OnLoaded.Event:Wait()
end

----------------------------------------------------------------------
-- Screen
----------------------------------------------------------------------
local old = H.guiParent():FindFirstChild("FlakeKeySystemScreen")
if old then old:Destroy() end

local screen = H.make("ScreenGui", {
    Name = "FlakeKeySystemScreen", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10000, IgnoreGuiInset = true,
})
H.protect(screen)
screen.Parent = H.guiParent()

local container = H.make("Frame", { Name = "Container", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1 }, screen)

----------------------------------------------------------------------
-- Key panel
----------------------------------------------------------------------
local panel = card(container, 560, 280)
local panelGlide = glider(panel)

closeButton(panel) -- close button wired after closeUI is defined

local title = H.make("TextLabel", {
    Name = "Name", Size = UDim2.new(0.84, 0, 0.14, 0), Position = UDim2.new(0.5, 0, 0.14, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, Text = "Key System", TextColor3 = TEXT_MAIN, TextScaled = true, FontFace = michroma(Enum.FontWeight.Bold),
}, panel)
cap(title, 30)

local subtitle = H.make("TextLabel", {
    Name = "Subtitle", Size = UDim2.new(0.82, 0, 0.11, 0), Position = UDim2.new(0.5, 0, 0.29, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, Text = "Please enter the key required to access the features in Flake.",
    TextColor3 = TEXT_DIM, TextScaled = true, TextWrapped = true, FontFace = michroma(Enum.FontWeight.Regular),
}, panel)
cap(subtitle, 13)

local box = H.make("TextBox", {
    Name = "KeyTextbox", Size = UDim2.new(0.74, 0, 0.13, 0), Position = UDim2.new(0.5, 0, 0.45, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = FIELD_BG, Text = "", PlaceholderText = "Enter key", PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
    TextColor3 = TEXT_MAIN, ClearTextOnFocus = false, ClipsDescendants = true, TextScaled = true, FontFace = michroma(Enum.FontWeight.Regular),
}, panel)
corner(box, 8)
cap(box, 16)
H.make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }, box)
local boxStroke = H.make("UIStroke", { Color = STROKE, Thickness = 1, Transparency = 0.7, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, box)

local enter = H.make("TextButton", {
    Name = "ButtonEnterKey", Size = UDim2.new(0.42, 0, 0.12, 0), Position = UDim2.new(0.5, 0, 0.60, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = BTN_BG, Text = "Enter", TextColor3 = TEXT_MAIN, TextScaled = true, FontFace = michroma(Enum.FontWeight.Medium),
}, panel)
corner(enter, 8)
cap(enter, 16)
wireButton(enter, BTN_BG, BTN_HOV, BTN_PRESS)

local status = H.make("TextLabel", {
    Name = "Status", Size = UDim2.new(0.84, 0, 0.055, 0), Position = UDim2.new(0.5, 0, 0.73, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, Text = "", TextColor3 = BAD_COLOR, TextTransparency = 1, TextScaled = true, FontFace = michroma(Enum.FontWeight.Medium),
}, panel)
cap(status, 13)

local howto = H.make("TextButton", {
    Name = "ButtonHowtoKey", Size = UDim2.new(0.55, 0, 0.07, 0), Position = UDim2.new(0.5, 0, 0.85, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, Text = "How do I get a key?", TextColor3 = TEXT_DIM, TextScaled = true, FontFace = michroma(Enum.FontWeight.Regular), AutoButtonColor = false,
}, panel)
cap(howto, 13)
howto.MouseEnter:Connect(function() TweenService:Create(howto, FAST, { TextColor3 = TEXT_MAIN }):Play() end)
howto.MouseLeave:Connect(function() TweenService:Create(howto, FAST, { TextColor3 = TEXT_DIM }):Play() end)

H.make("TextLabel", {
    Name = "Credits", Size = UDim2.new(0.5, 0, 0.05, 0), Position = UDim2.new(0.5, 0, 0.945, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, Text = "Made by JitLit_MDF", TextColor3 = Color3.fromRGB(110, 110, 110), TextScaled = true, FontFace = michroma(Enum.FontWeight.Regular),
}, panel)
cap(panel.Credits, 11)

----------------------------------------------------------------------
-- "How to get a key" popup
----------------------------------------------------------------------
local popup = card(container, 560, 340)
popup.Name = "Popup"
popup.Visible = false
local popupGlide = glider(popup)
closeButton(popup)

H.make("TextLabel", {
    Name = "Title", Size = UDim2.new(0.84, 0, 0.13, 0), Position = UDim2.new(0.5, 0, 0.12, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, Text = "How to get a key", TextColor3 = TEXT_MAIN, TextScaled = true, FontFace = michroma(Enum.FontWeight.Bold),
}, popup)
cap(popup.Title, 26)

local content = H.make("Frame", {
    Name = "Content", Size = UDim2.new(0.86, 0, 0.62, 0), Position = UDim2.new(0.5, 0, 0.52, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
}, popup)
H.make("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Left, VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0.035, 0) }, content)

local steps = {
    "1.  Must be friends with JitLit_MDF for 5 months.",
    "2.  Ask politely for the key to Flake Hub.",
    "3.  Patiently wait while I verify you're worthy of a key.",
}
for i, line in ipairs(steps) do
    local l = H.make("TextLabel", {
        Name = "Step" .. i, Size = UDim2.new(1, 0, 0.18, 0), BackgroundTransparency = 1, Text = line, TextColor3 = TEXT_MAIN,
        TextScaled = true, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
        FontFace = michroma(Enum.FontWeight.Regular), LayoutOrder = i,
    }, content)
    cap(l, 15)
end
local disclaimer = H.make("TextLabel", {
    Name = "Disclaimer", Size = UDim2.new(1, 0, 0.30, 0), BackgroundTransparency = 1,
    Text = "DISCLAIMER: I know this is very corny, but nobody is getting access to this hub unless I know you well.",
    TextColor3 = TEXT_DIM, TextScaled = true, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    FontFace = michroma(Enum.FontWeight.Regular), LayoutOrder = 10,
}, content)
cap(disclaimer, 12)

local backBtn = H.make("TextButton", {
    Name = "Back", Size = UDim2.new(0.30, 0, 0.1, 0), Position = UDim2.new(0.5, 0, 0.92, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = BTN_BG, Text = "Back", TextColor3 = TEXT_MAIN, TextScaled = true, FontFace = michroma(Enum.FontWeight.Medium),
}, popup)
corner(backBtn, 8)
cap(backBtn, 15)
wireButton(backBtn, BTN_BG, BTN_HOV, BTN_PRESS)

----------------------------------------------------------------------
-- Behaviour
----------------------------------------------------------------------
local CENTER = UDim2.new(0.5, 0, 0.5, 0)

box.Focused:Connect(function()
    TweenService:Create(box, FAST, { BackgroundColor3 = FIELD_FOC }):Play()
    TweenService:Create(boxStroke, FAST, { Transparency = 0.3 }):Play()
end)

local function showStatus(msg, color)
    status.Text = msg; status.TextColor3 = color
    TweenService:Create(status, TweenInfo.new(0.18), { TextTransparency = 0 }):Play()
end
local function clearStatus() TweenService:Create(status, TweenInfo.new(0.3), { TextTransparency = 1 }):Play() end
local function shake()
    local base = panelGlide.get()
    for _, off in ipairs({ 10, -10, 7, -7, 4, -4, 0 }) do
        panelGlide.set(base + UDim2.fromOffset(off, 0)); task.wait(0.03)
    end
    panelGlide.set(base)
end

local submit
box.FocusLost:Connect(function(enterPressed)
    TweenService:Create(box, FAST, { BackgroundColor3 = FIELD_BG }):Play()
    TweenService:Create(boxStroke, FAST, { Transparency = 0.7 }):Play()
    if enterPressed then submit() end
end)

local function closeUI()
    panelGlide.set(CENTER + UDim2.fromScale(0, 1.3))
    local sc = panel:FindFirstChildOfClass("UIScale")
    TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.9 }):Play()
    task.wait(0.4)
    screen:Destroy()
end
panel.Close.MouseButton1Click:Connect(closeUI)

local submitted = false
submit = function()
    if submitted then return end
    if box.Text == KEY then
        submitted = true
        Flake.Key = box.Text; Flake.Authorized = true; getgenv().FlakeAuthorized = true
        showStatus("Access granted. Loading Flake...", OK_COLOR)
        TweenService:Create(box, FAST, { BackgroundColor3 = OK_COLOR }):Play()
        TweenService:Create(boxStroke, FAST, { Color = OK_COLOR, Transparency = 0 }):Play()
        enter.Text = "OK"; TweenService:Create(enter, FAST, { BackgroundColor3 = OK_COLOR }):Play()
        Flake.OnAuthorized:Fire(box.Text)
        task.wait(0.85)
        closeUI()
    else
        showStatus("Invalid key, try again.", BAD_COLOR)
        TweenService:Create(boxStroke, FAST, { Color = BAD_COLOR, Transparency = 0 }):Play()
        task.spawn(shake)
        task.delay(1.6, function()
            if not submitted and box and box.Parent then
                clearStatus(); TweenService:Create(boxStroke, FAST, { Color = STROKE, Transparency = 0.7 }):Play()
            end
        end)
    end
end
enter.MouseButton1Click:Connect(submit)

-- Howto -> popup
howto.MouseButton1Click:Connect(function()
    popup.Visible = true
    popIn(popup, CENTER)
    popupGlide.set(CENTER)
    -- slide the key panel back a touch (depth cue)
    local sc = panel:FindFirstChildOfClass("UIScale")
    TweenService:Create(sc, TweenInfo.new(0.3), { Scale = 0.95 }):Play()
    TweenService:Create(panel, TweenInfo.new(0.3), { BackgroundTransparency = 0.25 }):Play()
end)
local function closePopup()
    popupGlide.set(CENTER + UDim2.fromScale(0, 0.4))
    local sc = popup:FindFirstChildOfClass("UIScale")
    TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.92 }):Play()
    local ps = panel:FindFirstChildOfClass("UIScale")
    TweenService:Create(ps, TweenInfo.new(0.3), { Scale = 1 }):Play()
    TweenService:Create(panel, TweenInfo.new(0.3), { BackgroundTransparency = 0 }):Play()
    task.wait(0.32)
    popup.Visible = false
end
backBtn.MouseButton1Click:Connect(closePopup)
popup.Close.MouseButton1Click:Connect(closePopup)

----------------------------------------------------------------------
-- Entrance
----------------------------------------------------------------------
panelGlide.set(CENTER)
popIn(panel, CENTER)

return Flake
