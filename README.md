# PowerGridCC

CC:Tweaked apartment electricity meter for Create: Power Grid.

## Features

- Automatically searches **all available peripherals**.
- Does not require the gauge to be on the left side.
- Works with peripherals connected through wired modem networks.
- Prefers the exact `powergrid_power_gauge` peripheral type.
- Falls back to any peripheral exposing `getPower()`.
- Reads power in watts and integrates it into cumulative kWh.
- Saves the counter in `apartment_kwh.dat`.
- Keeps the counter after computer restarts.
- Automatically detects reconnects.
- No `require()` and no external libraries.

## Install

```lua
wget run https://raw.githubusercontent.com/Frez7373/powergridcc/main/install.lua
```

Then:

```lua
kwhmeter
```

## Wiring

The gauge can be connected on any side or through a compatible wired peripheral network.

The program scans all devices using:

```lua
peripheral.getNames()
```

and looks for:

```lua
getPower()
```

## Calculation

```text
kWh += watts × elapsed_seconds / 3,600,000
```

## Reset

Stop the program and delete:

```text
apartment_kwh.dat
```

Then start `kwhmeter` again.

## Installer

The installer downloads the latest `kwhmeter.lua` from the repository and overwrites the local program.
