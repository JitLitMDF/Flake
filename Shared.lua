--[[
    Flake // Shared.lua
    Shared runtime state + tiny GUI helpers used by Loader and Keysystem.
    Loaded automatically by both scripts; safe to require multiple times.
    Made by JitLit_MDF
]]

local getgenv = getgenv or function() return _G end

local Flake = getgenv().Flake
if not Flake then
    Flake = {
        Version   = "1.0.0",
        Loaded    = false, -- set true when the loader finishes
        Authorized= false, -- set true when a valid key is entered
        Key       = nil,   -- the key the user typed (once authorized)
        Signals   = {},    -- BindableEvents, created lazily below
    }
    getgenv().Flake = Flake
end

-- Lazily create the handoff signals so either script can connect first.
local function signal(name)
    if not Flake.Signals[name] then
        Flake.Signals[name] = Instance.new("BindableEvent")
    end
    return Flake.Signals[name]
end
Flake.OnLoaded     = signal("OnLoaded")     -- fires() when loader done
Flake.OnAuthorized = signal("OnAuthorized") -- fires(key) when key accepted

-- Backwards-compatible flat globals (the original build set these directly).
getgenv().FlakeLoaded      = getgenv().FlakeLoaded or false
getgenv().FlakeAuthorized  = getgenv().FlakeAuthorized or false

----------------------------------------------------------------------
-- GUI helpers
----------------------------------------------------------------------
local Helpers = {}

-- Pick the safest place to parent protected GUIs under an executor.
function Helpers.guiParent()
    local hui = rawget(getgenv(), "gethui") or gethui
    if typeof(hui) == "function" then
        local ok, res = pcall(hui)
        if ok and res then return res end
    end
    return game:GetService("CoreGui")
end

-- Hide a ScreenGui from CoreGui scrapers where the executor supports it.
function Helpers.protect(gui)
    local protectors = {
        rawget(getgenv(), "protect_gui"),
        (syn and syn.protect_gui),
    }
    for _, fn in ipairs(protectors) do
        if typeof(fn) == "function" then pcall(fn, gui) end
    end
    return gui
end

function Helpers.michroma(weight, style)
    return Font.new(
        "rbxasset://fonts/families/Michroma.json",
        weight or Enum.FontWeight.Bold,
        style  or Enum.FontStyle.Normal
    )
end

-- make("Frame", { Size = ... }, parent) -> Instance
function Helpers.make(className, props, parent)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

Flake.Helpers = Helpers
return Flake
