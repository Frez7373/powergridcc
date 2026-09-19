-- PowerGridCC installer
-- Run with:
-- wget run https://raw.githubusercontent.com/Frez7373/powergridcc/main/install.lua

local BASE_URL = "https://raw.githubusercontent.com/Frez7373/powergridcc/main/"
local PROGRAM_URL = BASE_URL .. "kwhmeter.lua"
local PROGRAM_PATH = "/kwhmeter.lua"

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)

print("PowerGridCC - Apartment kWh Meter")
print("----------------------------------")
print("Installing " .. PROGRAM_PATH)
print("")

if not http then
    error("HTTP API is disabled. Enable HTTP in CC:Tweaked config.")
end

local response = http.get(PROGRAM_URL)
if not response then
    error("Unable to download kwhmeter.lua")
end

local content = response.readAll()
response.close()

local file = fs.open(PROGRAM_PATH, "w")
if not file then
    error("Unable to write " .. PROGRAM_PATH)
end

file.write(content)
file.close()

print("Installation complete.")
print("")
print("Run:")
print("  kwhmeter")
print("")
print("The meter expects a powergrid_power_gauge")
print("connected directly to the LEFT side.")
