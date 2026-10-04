--[[
    Flake // Main.lua  (the entry point)
    This is the single loadstring you paste into your executor:

        loadstring(game:HttpGet("https://raw.githubusercontent.com/JitLitMDF/Flake/main/Main.lua"))()

    It runs the loader, then the key gate, then (optionally) the hub.
    Made by JitLit_MDF
]]

local BASE = "https://raw.githubusercontent.com/JitLitMDF/Flake/main/"

local function fetch(name)
    return loadstring(game:HttpGet(BASE .. name))()
end

-- Shared state first so everything coordinates through one table.
local Flake = fetch("Shared.lua")

-- Intro / verify screen.
fetch("Loader.lua")

-- Key gate (it waits for the loader's OnLoaded internally).
fetch("Keysystem.lua")

-- When authorized, boot the hub. Hub.lua is optional: if it isn't in the
-- repo yet this just no-ops instead of erroring.
Flake.OnAuthorized.Event:Connect(function(key)
    local ok, err = pcall(fetch, "Hub.lua")
    if not ok then
        warn("[Flake] Hub not loaded: " .. tostring(err))
    end
end)

return Flake
