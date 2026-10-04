--[[
    Flake // Loader.lua
    The intro / "verifying" screen. Slides a card up, runs a short spinner
    sequence, then flips the shared Loaded flag and fires OnLoaded so the
    Keysystem can take over.
    Made by JitLit_MDF
]]

local BASE = "https://raw.githubusercontent.com/JitLitMDF/Flake/main/"

local Flake = getgenv and getgenv().Flake
if not (Flake and Flake.Helpers) then
    Flake = loadstring(game:HttpGet(BASE .. "Shared.lua"))()
end
local H = Flake.Helpers

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

----------------------------------------------------------------------
-- Config / theme (shared look with the keysystem)
----------------------------------------------------------------------
local STATUS_STEPS = {
    { text = "INITIALIZING", hold = 0.9 },
    { text = "VERIFYING",    hold = 1.1 },
}
local PANEL_BG  = Color3.fromRGB(47, 47, 47)
local TEXT_MAIN = Color3.fromRGB(241, 241, 241)
local TEXT_DIM  = Color3.fromRGB(150, 150, 150)
local STROKE    = Color3.fromRGB(255, 255, 255)
local ACCENT    = Color3.fromRGB(241, 241, 241)
local MICHROMA  = "rbxasset://fonts/families/Michroma.json"

local function corner(p, r) return H.make("UICorner", { CornerRadius = UDim.new(0, r or 12) }, p) end
local function capText(o, mx) H.make("UITextSizeConstraint", { MaxTextSize = mx or 28, MinTextSize = 6 }, o) end

----------------------------------------------------------------------
-- Build
----------------------------------------------------------------------
local old = H.guiParent():FindFirstChild("FlakeLoadingScreen")
if old then old:Destroy() end

local screen = H.make("ScreenGui", {
    Name = "FlakeLoadingScreen",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 10000,
    IgnoreGuiInset = true,
})
H.protect(screen)
screen.Parent = H.guiParent()

local container = H.make("Frame", {
    Name = "Container",
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
}, screen)

local panel = H.make("Frame", {
    Name = "Frame",
    Size = UDim2.fromOffset(600, 360),
    Position = UDim2.new(0.5, 0, 1.5, 0), -- off-screen; tweens up to centre
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = PANEL_BG,
}, container)

H.make("UIAspectRatioConstraint", {
    AspectRatio = 600 / 360,
    AspectType = Enum.AspectType.ScaleWithParentSize,
    DominantAxis = Enum.DominantAxis.Width,
}, panel)
H.make("UISizeConstraint", { MinSize = Vector2.new(440, 264), MaxSize = Vector2.new(760, 456) }, panel)
H.make("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(21, 21, 21)),
    }),
    Offset = Vector2.new(0, 10),
}, panel)
corner(panel, 14)
H.make("UIStroke", {
    Color = STROKE, Thickness = 2, Transparency = 0.15,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Round,
}, panel)

H.make("ImageLabel", {
    Name = "Shadow",
    Size = UDim2.new(1, 56, 1, 56),
    Position = UDim2.new(0.5, 0, 0.5, 8),
    AnchorPoint = Vector2.new(0.5, 0.5),
    ZIndex = -1,
    BackgroundTransparency = 1,
    Image = "rbxassetid://6015897843",
    ImageColor3 = Color3.fromRGB(0, 0, 0),
    ImageTransparency = 0.4,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(49, 49, 463, 463),
}, panel)

-- Title "Flake"
local title = H.make("TextLabel", {
    Name = "Name",
    Size = UDim2.new(0.7, 0, 0, 92),
    Position = UDim2.new(0.5, 0, 0.19, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundTransparency = 1,
    Text = "Flake",
    TextColor3 = TEXT_MAIN,
    TextScaled = true,
    FontFace = Font.new(MICHROMA, Enum.FontWeight.Bold),
}, panel)
capText(title, 84)

-- underline bar beneath the title
H.make("Frame", {
    Name = "Underline",
    Size = UDim2.new(0.5, 0, 0, 2),
    Position = UDim2.new(0.5, 0, 0.505, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundColor3 = ACCENT,
    BorderSizePixel = 0,
}, panel)

-- tagline
local info = H.make("TextLabel", {
    Name = "Info",
    Size = UDim2.new(0.82, 0, 0, 20),
    Position = UDim2.new(0.5, 0, 0.55, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundTransparency = 1,
    Text = "A Private ScriptHub for all your niche games",
    TextColor3 = TEXT_DIM,
    TextScaled = true,
    TextWrapped = true,
    FontFace = Font.new(MICHROMA, Enum.FontWeight.Regular),
}, panel)
capText(info, 16)

-- status row: spinner + word, centered as a unit
local spinner = H.make("ImageLabel", {
    Name = "LoadSpinner",
    Size = UDim2.fromOffset(26, 26),
    Position = UDim2.new(0.335, 0, 0.72, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Image = "rbxassetid://110507486450516",
    ImageColor3 = TEXT_MAIN,
    ScaleType = Enum.ScaleType.Fit,
}, panel)

local loadingSign = H.make("TextLabel", {
    Name = "LoadingSign",
    Size = UDim2.new(0, 170, 0, 22),
    Position = UDim2.new(0.37, 0, 0.72, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundTransparency = 1,
    Text = STATUS_STEPS[1].text,
    TextColor3 = TEXT_MAIN,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextScaled = true,
    FontFace = Font.new(MICHROMA, Enum.FontWeight.Medium),
}, panel)
capText(loadingSign, 16)

H.make("TextLabel", {
    Name = "Credits",
    Size = UDim2.new(0, 150, 0, 12),
    Position = UDim2.new(0.5, 0, 0.93, 0),
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundTransparency = 1,
    Text = "Made by JitLit_MDF",
    TextColor3 = Color3.fromRGB(110, 110, 110),
    TextScaled = true,
    FontFace = Font.new(MICHROMA, Enum.FontWeight.Regular),
}, panel)

----------------------------------------------------------------------
-- Animate
----------------------------------------------------------------------
local spinConn
spinConn = RunService.RenderStepped:Connect(function(dt)
    if spinner and spinner.Parent then
        spinner.Rotation = (spinner.Rotation + dt * 320) % 360
    else
        spinConn:Disconnect()
    end
end)

TweenService:Create(panel, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, 0, 0.5, 0),
}):Play()

task.spawn(function()
    for _, step in ipairs(STATUS_STEPS) do
        loadingSign.Text = step.text
        task.wait(step.hold)
    end

    Flake.Loaded = true
    getgenv().FlakeLoaded = true
    Flake.OnLoaded:Fire()

    if spinConn then spinConn:Disconnect() end
    local out = TweenService:Create(panel, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, 0, 1.6, 0),
    })
    out:Play()
    out.Completed:Wait()
    screen:Destroy()
end)

return Flake
