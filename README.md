# PowerGridCC

CC:Tweaked apartment electricity meter for Create: Power Grid.

## Features

- Automatically searches **all available peripherals**.
- Does not require the gauge to be on the left side.
- Works with peripherals connected through wired modem networks.
- Prefers the exact `powergrid_power_gauge` peripheral type.
- Uses the current `power()` API of `powergrid_power_gauge`.
- Supports older integrations exposing `getValue()`.
- Reads power in watts and integrates it into cumulative kWh.
- Saves the counter in `apartment_kwh.dat`.
- Keeps the counter after computer restarts.
- Automatically detects reconnects.
- Records power outages with date/time when power goes off and when it returns.
- Shows the last 5 outages as a checklist on screen.
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

and looks for the Power Grid peripheral type:

```text
powergrid_power_gauge
```

The current API is read with:

```lua
power()
```

Older CC Power Grid integrations using `getValue()` are also supported.

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

## Outage checklist

The meter detects a transition to approximately 0 W and records the outage start time. When power returns, it records the recovery time. Up to 10 events are stored; the screen shows the latest 5.

## Installer

The installer downloads the latest `kwhmeter.lua` from the repository and overwrites the local program.
