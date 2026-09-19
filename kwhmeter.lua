-- Apartment Power Meter for CC:Tweaked
-- Reads a Create: Power Grid power gauge on the LEFT side.
-- Peripheral type: powergrid_power_gauge
-- Expected method: getPower() -> power in watts (W)

local GAUGE_SIDE = "left"
local DATA_FILE = "apartment_kwh.dat"
local SAMPLE_SECONDS = 1

local function fail(message)
    term.setTextColor(colors.red)
    print("ERROR: " .. message)
    term.setTextColor(colors.white)
end

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
            version = 1,
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

    data.version = tonumber(data.version) or 1
    data.total_kwh = tonumber(data.total_kwh) or 0
    data.samples = tonumber(data.samples) or 0

    return data
end

local function find_gauge()
    if not peripheral.isPresent(GAUGE_SIDE) then
        return nil, "No peripheral on the left side"
    end

    local gauge = peripheral.wrap(GAUGE_SIDE)
    if not gauge then
        return nil, "Cannot wrap peripheral on the left side"
    end

    local has_get_power = false
    local methods = peripheral.getMethods(GAUGE_SIDE) or {}

    for _, method in ipairs(methods) do
        if method == "getPower" then
            has_get_power = true
            break
        end
    end

    if not has_get_power then
        return nil, "Peripheral on the left has no getPower() method"
    end

    return gauge
end

local function read_power(gauge)
    local ok, value = pcall(gauge.getPower)

    if not ok then
        return nil, "getPower() failed: " .. tostring(value)
    end

    value = tonumber(value)

    if not value then
        return nil, "getPower() did not return a number"
    end

    -- A household meter counts consumed energy, so use the magnitude
    -- of the power flow. This also handles a reversed gauge connection.
    return math.abs(value)
end

local function format_energy(kwh)
    if kwh >= 1000000 then
        return string.format("%.3f MWh", kwh / 1000)
    end
    return string.format("%.3f kWh", kwh)
end

local function draw(data, power, connected)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)

    print("APARTMENT POWER METER")
    print("---------------------")
    print("Gauge: " .. GAUGE_SIDE)

    if connected then
        term.setTextColor(colors.lime)
        print("Status: CONNECTED")
        term.setTextColor(colors.white)
        print(string.format("Power : %.2f W", power or 0))
    else
        term.setTextColor(colors.red)
        print("Status: DISCONNECTED")
        term.setTextColor(colors.white)
        print("Power : --")
    end

    print("")
    print("Total energy:")
    term.setTextColor(colors.yellow)
    print(format_energy(data.total_kwh))
    term.setTextColor(colors.white)

    print("")
    print("Samples: " .. tostring(data.samples))
    print("")
    print("Data: " .. DATA_FILE)
    print("")
    print("Press Ctrl+T to stop.")
end

local function main()
    local data = load()

    local gauge, gauge_error = find_gauge()
    if not gauge then
        fail(gauge_error)
        print("")
        print("Connect the power gauge to the LEFT side")
        print("of this computer and restart kwhmeter.")
        return
    end

    print("Starting apartment power meter...")
    sleep(1)

    local last_time = os.clock()

    while true do
        -- Re-check the peripheral every cycle so unplugging/reconnecting
        -- does not permanently break the meter.
        gauge, gauge_error = find_gauge()

        if gauge then
            local power, read_error = read_power(gauge)

            if power then
                local now = os.clock()
                local elapsed = now - last_time

                -- Protect against unusual clock jumps.
                if elapsed < 0 then
                    elapsed = 0
                elseif elapsed > 10 then
                    elapsed = SAMPLE_SECONDS
                end

                -- W * seconds / 3,600,000 = kWh
                data.total_kwh = data.total_kwh + (power * elapsed / 3600000)
                data.samples = data.samples + 1

                last_time = now

                -- Save every sample so a computer restart loses at most
                -- the current sampling interval.
                save(data)
                draw(data, power, true)
            else
                last_time = os.clock()
                draw(data, 0, false)
                term.setCursorPos(1, 16)
                term.setTextColor(colors.red)
                print(read_error)
                term.setTextColor(colors.white)
            end
        else
            last_time = os.clock()
            draw(data, 0, false)
            term.setCursorPos(1, 16)
            term.setTextColor(colors.red)
            print(gauge_error or "Unknown gauge error")
            term.setTextColor(colors.white)
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
