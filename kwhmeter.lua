-- PowerGridCC Apartment kWh Meter
-- Automatically discovers a Power Grid power gauge anywhere in the
-- connected peripheral network. No fixed side is required.
--
-- Priority:
-- 1. Peripheral type "powergrid_power_gauge"
-- 2. Any peripheral exposing getPower()
--
-- CC:Tweaked only. No require() or external libraries.

local DATA_FILE = "apartment_kwh.dat"
local SAMPLE_SECONDS = 1

local function save(data)
    local file = fs.open(DATA_FILE, "w")
    if not file then
        error("Cannot open " .. DATA_FILE .. " for writing")
    end

    file.write(textutils.serialize(data))
    file.close()
end

local function load()
    if not fs.exists(DATA_FILE) then
        local data = {
            version = 2,
            total_kwh = 0,
            samples = 0
        }
        save(data)
        return data
    end

    local file = fs.open(DATA_FILE, "r")
    if not file then
        error("Cannot open " .. DATA_FILE .. " for reading")
    end

    local raw = file.readAll()
    file.close()

    local data = textutils.unserialize(raw)

    if type(data) ~= "table" then
        error("Invalid data file: " .. DATA_FILE)
    end

    data.version = tonumber(data.version) or 2
    data.total_kwh = tonumber(data.total_kwh) or 0
    data.samples = tonumber(data.samples) or 0

    return data
end

local function has_method(name, method)
    local ok, methods = pcall(peripheral.getMethods, name)
    if not ok or type(methods) ~= "table" then
        return false
    end

    for _, listed in ipairs(methods) do
        if listed == method then
            return true
        end
    end

    return false
end

local function discover_gauge()
    local names = peripheral.getNames()

    -- First prefer the exact Power Grid peripheral type.
    for _, name in ipairs(names) do
        local ptype = peripheral.getType(name)

        if ptype == "powergrid_power_gauge" and has_method(name, "getPower") then
            return name, ptype
        end
    end

    -- Fallback: find any peripheral with getPower().
    for _, name in ipairs(names) do
        if has_method(name, "getPower") then
            return name, peripheral.getType(name) or "unknown"
        end
    end

    return nil, nil
end

local function read_power(name)
    local ok, value = pcall(peripheral.call, name, "getPower")

    if not ok then
        return nil, "getPower() failed: " .. tostring(value)
    end

    value = tonumber(value)

    if not value then
        return nil, "getPower() did not return a number"
    end

    -- Count the magnitude so reversed gauge orientation does not
    -- produce negative apartment consumption.
    return math.abs(value)
end

local function format_energy(kwh)
    if kwh >= 1000 then
        return string.format("%.3f MWh", kwh / 1000)
    end

    return string.format("%.3f kWh", kwh)
end

local function draw(data, gauge_name, gauge_type, power, connected, error_text)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)

    print("APARTMENT POWER METER")
    print("=====================")
    print("")

    if connected then
        term.setTextColor(colors.lime)
        print("Status : CONNECTED")
        term.setTextColor(colors.white)
        print("Device : " .. tostring(gauge_name))
        print("Type   : " .. tostring(gauge_type))
        print(string.format("Power  : %.2f W", power or 0))
    else
        term.setTextColor(colors.red)
        print("Status : SEARCHING")
        term.setTextColor(colors.white)
        print("Device : not found")

        if error_text then
            print("")
            term.setTextColor(colors.red)
            print(error_text)
            term.setTextColor(colors.white)
        end
    end

    print("")
    print("TOTAL ENERGY")
    term.setTextColor(colors.yellow)
    print(format_energy(data.total_kwh))
    term.setTextColor(colors.white)

    print("")
    print("Samples: " .. tostring(data.samples))
    print("Data   : " .. DATA_FILE)
    print("")
    print("Automatic device discovery: ON")
    print("Press Ctrl+T to stop.")
end

local function main()
    local data = load()
    local last_time = os.clock()

    while true do
        local gauge_name, gauge_type = discover_gauge()

        if gauge_name then
            local power, read_error = read_power(gauge_name)

            if power then
                local now = os.clock()
                local elapsed = now - last_time

                -- Ignore impossible time jumps.
                if elapsed < 0 then
                    elapsed = 0
                elseif elapsed > 10 then
                    elapsed = SAMPLE_SECONDS
                end

                -- W * seconds / 3,600,000 = kWh
                data.total_kwh = data.total_kwh + (power * elapsed / 3600000)
                data.samples = data.samples + 1

                last_time = now
                save(data)
                draw(data, gauge_name, gauge_type, power, true)
            else
                last_time = os.clock()
                draw(data, gauge_name, gauge_type, 0, false, read_error)
            end
        else
            last_time = os.clock()
            draw(
                data,
                nil,
                nil,
                0,
                false,
                "No power gauge with getPower() was found."
            )
        end

        sleep(SAMPLE_SECONDS)
    end
end

local ok, err = pcall(main)

if not ok then
    term.setTextColor(colors.red)
    print("")
    print("Meter stopped because of an error:")
    print(tostring(err))
    term.setTextColor(colors.white)
end
