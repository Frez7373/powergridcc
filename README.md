# PowerGridCC

CC:Tweaked apartment electricity meter for Create: Power Grid.

## What it does

- Reads the power from a `powergrid_power_gauge`.
- The gauge is expected on the **left** side of the computer.
- Uses the gauge `getPower()` value as watts.
- Integrates power over elapsed real time and stores the result in **kWh**.
- Saves the accumulated value to `apartment_kwh.dat`.
- Survives computer restarts without resetting the accumulated total.
- Automatically handles the gauge being temporarily disconnected.
- No `require()` and no external Lua libraries.

## Install

Run in CC:Tweaked:

```lua
wget run https://raw.githubusercontent.com/Frez7373/powergridcc/main/install.lua
```

Then start:

```lua
kwhmeter
```

## Wiring

Place the CC:Tweaked computer/terminal next to the Power Grid power gauge so that the gauge is on the computer's **left** side.

The program checks for the `getPower()` method instead of relying only on the peripheral type string.

## Calculation

```text
kWh += watts × elapsed_seconds / 3,600,000
```

The stored value is cumulative and is not reset when the program restarts.

## Data file

`apartment_kwh.dat` contains the current cumulative reading. Keep this file to preserve the meter value.

## Reset

To reset the meter, stop the program and delete:

```text
apartment_kwh.dat
```

Then start `kwhmeter` again. A new counter will be created at 0 kWh.

## Compatibility

Designed for CC:Tweaked and Power Grid peripherals exposing a `getPower()` method.
